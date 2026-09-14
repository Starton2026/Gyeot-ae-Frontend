import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import 'notification_providers.dart';
import 'widgets/notification_empty_view.dart';
import 'widgets/notification_tile.dart';

/// 알림함. 상단바 알림 버튼(기능정의서 5.5)이 연다.
///
/// **명세서에 없는 화면이다.** 푸시는 한 번 스치면 사라지고, 폰이 꺼져 있었으면
/// 아예 못 본다. 받은 소식을 다시 찾아갈 자리가 필요해서 만들었다.
///
/// 열면 서버에서 전부 읽음이 되고 상단바 점이 꺼진다. **줄마다의 강조는 이
/// 화면을 보는 동안 남긴다.** 연 순간 다 지우면 무엇이 새로 왔는지 읽기도 전에
/// 구분이 사라진다.
class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  /// 이 화면을 보는 동안 안 읽은 상태로 받았던 알림. 읽음 처리 뒤에도 강조한다.
  final Set<String> _fresh = {};

  @override
  void initState() {
    super.initState();

    // 보는 동안 새 알림이 들어와 다시 받아도 그것까지 읽음으로 한다.
    ref.listenManual(notificationInboxProvider, (previous, next) {
      if ((next.value?.unreadCount ?? 0) == 0) return;
      unawaited(ref.read(notificationInboxProvider.notifier).markAllRead());
    }, fireImmediately: true);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(notificationInboxProvider);
    _fresh.addAll(
      inbox.value?.items.where((item) => !item.read).map((item) => item.id) ??
          const <String>[],
    );

    return Scaffold(
      appBar: AppTopBar.back('알림', onBack: _goBack),
      body: inbox.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: error is ApiException
              ? error.message
              : '알림을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
          onRetry: () => ref.invalidate(notificationInboxProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationInboxProvider.future),
          child: data.isEmpty
              // 비어 있어도 당겨서 새로고침할 수 있게 스크롤 안에 둔다.
              ? ListView(children: const [NotificationEmptyView()])
              : ListView.separated(
                  itemCount: data.items.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = data.items[index];

                    return NotificationTile(
                      notification: item,
                      fresh: _fresh.contains(item.id),
                      onTap: () => unawaited(
                        context.push(AppRoute.missingDetail(item.caseId)),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
