import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/app_notification.dart';
import '../data/notification_repository.dart';

/// 알림함. 상단바 점과 알림 화면이 같은 값을 본다.
///
/// 다시 받는 때: 로그인이 바뀔 때(계정에 온 알림이 갈린다), 앱이 앞으로
/// 돌아올 때와 푸시가 도착했을 때(`GyeotaeApp`이 invalidate한다), 알림 화면에서
/// 당겨서 새로고침할 때.
class NotificationInboxNotifier extends AsyncNotifier<NotificationInbox> {
  @override
  Future<NotificationInbox> build() async {
    ref.watch(authProvider.select((auth) => auth.value?.id));

    return ref.watch(notificationRepositoryProvider).fetchInbox();
  }

  /// 알림함을 열었다. 서버에 전부 읽음을 알리고 상단바 점을 끈다.
  ///
  /// 실패해도 조용히 넘어간다. 점이 한 번 더 남는 것보다 알림 화면에 오류가
  /// 뜨는 쪽이 더 거슬린다.
  Future<void> markAllRead() async {
    final inbox = state.value;
    if (inbox == null || inbox.unreadCount == 0) return;

    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
    } on Object catch (error) {
      debugPrint('알림을 읽음으로 바꾸지 못했습니다: $error');
      return;
    }
    if (!ref.mounted) return;

    // 그사이 새로 받아온 묶음이 있으면 그걸 기준으로 바꾼다.
    final latest = state.value ?? inbox;
    state = AsyncData(latest.markedRead());
  }
}

final notificationInboxProvider =
    AsyncNotifierProvider<NotificationInboxNotifier, NotificationInbox>(
      NotificationInboxNotifier.new,
      // 점 하나를 위해 뒤에서 계속 다시 부르지 않는다. 앱이 돌아오거나 푸시가
      // 오면 어차피 다시 받는다.
      retry: (retryCount, error) => null,
    );

/// 상단바 알림 버튼에 점을 찍을지. 못 받아왔으면 찍지 않는다.
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final inbox = ref.watch(notificationInboxProvider).value;

  return (inbox?.unreadCount ?? 0) > 0;
});
