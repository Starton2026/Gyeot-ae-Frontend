import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/link/case_link.dart';
import 'core/link/link_source.dart';
import 'core/push/push_alert_bar.dart';
import 'core/push/push_messaging.dart';
import 'core/push/push_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/notification_providers.dart';

class GyeotaeApp extends ConsumerStatefulWidget {
  const GyeotaeApp({super.key});

  @override
  ConsumerState<GyeotaeApp> createState() => _GyeotaeAppState();
}

class _GyeotaeAppState extends ConsumerState<GyeotaeApp> {
  /// 화면 어디에 있든 알림 막대를 띄울 수 있는 자리.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<PushOpen>? _opens;
  StreamSubscription<PushAlert>? _alerts;
  StreamSubscription<Uri>? _links;
  AppLifecycleListener? _lifecycle;

  /// 스플래시가 끝나기 전에 들어온 알림·링크가 열 곳.
  String? _pendingLocation;

  /// 한 번 잡아 둔다. `dispose`에서는 ref를 읽을 수 없는데 리스너를 떼야 한다.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(routerProvider);

    // 알림은 앱 뿌리에서 듣는다. 탭 껍데기에 두면 상세나 제보 화면이 덮여
    // 있을 때 못 듣는다.
    final messaging = ref.read(pushMessagingProvider);
    _opens = messaging.opens().listen(_openFromPush);
    _alerts = messaging.alerts().listen(_show);
    unawaited(messaging.initialOpen().then(_openFromPush));

    // 앱 링크·카카오톡 공유. 앱을 처음 띄운 링크도 이 흐름으로 온다.
    _links = ref.read(linkSourceProvider).links().listen(_openFromLink);

    _router.routerDelegate.addListener(_flushPending);

    // 앱을 다시 앞으로 가져오면 그사이 쌓인 알림이 있을 수 있다.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationInboxProvider),
    );
  }

  @override
  void dispose() {
    unawaited(_opens?.cancel());
    unawaited(_alerts?.cancel());
    unawaited(_links?.cancel());
    _lifecycle?.dispose();
    _router.routerDelegate.removeListener(_flushPending);
    super.dispose();
  }

  void _openFromPush(PushOpen? open) {
    if (open == null) return;

    ref.invalidate(notificationInboxProvider);
    _open(AppRoute.missingDetail(open.caseId));
  }

  void _openFromLink(Uri uri) {
    final caseId = CaseLink.caseIdFrom(uri);
    if (caseId == null) {
      debugPrint('사건 링크가 아니라 열지 않습니다: $uri');
      return;
    }

    _open(AppRoute.missingDetailFromLink(caseId));
  }

  /// 알림·링크가 가리키는 사건을 연다.
  ///
  /// **쌓아 올린다(push).** 알림으로 들어왔다고 홈을 지워 버리면, 뒤로 가기가
  /// 앱을 닫아 버려서 "무슨 일인지 보고 하던 걸로 돌아가기"가 안 된다.
  ///
  /// **스플래시 위에는 쌓지 않는다.** 스플래시는 끝나면서 홈으로 `go`해 쌓인
  /// 화면을 전부 걷어낸다. 알림을 눌러 앱을 켰는데 홈만 보이는 이유였다.
  /// 스플래시가 끝날 때까지 들고 있다가 연다.
  void _open(String location) {
    if (!mounted) return;

    if (_starting) {
      _pendingLocation = location;
      return;
    }

    unawaited(_router.push(location));
  }

  /// 아직 스플래시에 있는지. 첫 화면이 서기 전도 여기에 든다.
  bool get _starting {
    final current = _router.routerDelegate.currentConfiguration;

    return current.isEmpty || current.uri.path == AppRoute.splash;
  }

  void _flushPending() {
    final location = _pendingLocation;
    if (location == null || _starting) return;

    _pendingLocation = null;
    // 라우터가 화면을 바꾸는 도중이다. 그 한 프레임이 끝난 뒤 얹는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(location));
  }

  /// 앱이 켜져 있는 동안 온 알림을 직접 띄운다.
  void _show(PushAlert alert) {
    ref.invalidate(notificationInboxProvider);

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;

    final open = alert.open;
    messenger
      // 연달아 오면 마지막 것만 보여준다. 쌓아두면 지난 소식을 계속 읽게 된다.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        pushAlertBar(
          alert: alert,
          onOpen: open == null ? null : () => _openFromPush(open),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '곁애',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
