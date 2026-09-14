import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();

    // 알림은 앱 뿌리에서 듣는다. 탭 껍데기에 두면 상세나 제보 화면이 덮여
    // 있을 때 못 듣는다.
    final messaging = ref.read(pushMessagingProvider);
    _opens = messaging.opens().listen(_go);
    _alerts = messaging.alerts().listen(_show);

    // 알림을 눌러 앱이 **처음 뜬** 경우. 라우터가 첫 화면을 세우기 전에 밀어
    // 넣으면 조용히 무시되므로 한 프레임 기다린다.
    unawaited(
      messaging.initialOpen().then((open) {
        if (open == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _go(open));
      }),
    );

    // 앱을 다시 앞으로 가져오면 그사이 쌓인 알림이 있을 수 있다.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationInboxProvider),
    );
  }

  @override
  void dispose() {
    unawaited(_opens?.cancel());
    unawaited(_alerts?.cancel());
    _lifecycle?.dispose();
    super.dispose();
  }

  /// 알림이 가리키는 사건을 연다.
  ///
  /// **쌓아 올린다(push).** 알림으로 들어왔다고 홈을 지워 버리면, 뒤로 가기가
  /// 앱을 닫아 버려서 "무슨 일인지 보고 하던 걸로 돌아가기"가 안 된다.
  void _go(PushOpen? open) {
    if (open == null || !mounted) return;

    ref.invalidate(notificationInboxProvider);
    unawaited(
      ref.read(routerProvider).push(AppRoute.missingDetail(open.caseId)),
    );
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
          onOpen: open == null ? null : () => _go(open),
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
