import 'package:gyeotae/features/notifications/data/app_notification.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';

/// 알림함을 정해두고 돌려준다. 읽음 처리하면 서버처럼 전부 읽은 것으로 바꾼다.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({NotificationInbox? inbox, this.error})
    : inbox = inbox ?? const NotificationInbox.empty();

  NotificationInbox inbox;
  final Object? error;

  int fetches = 0;
  int markReadCalls = 0;

  @override
  Future<NotificationInbox> fetchInbox() async {
    fetches += 1;

    final failure = error;
    if (failure != null) throw failure;

    return inbox;
  }

  @override
  Future<void> markAllRead() async {
    markReadCalls += 1;
    inbox = inbox.markedRead();
  }
}

/// 알림 한 줄. 필요한 값만 이름으로 바꿔 쓴다.
AppNotification fakeNotification({
  String id = 'n_1',
  NotificationKind kind = NotificationKind.missing,
  String caseId = 'm_1',
  String title = '내 주변에서 실종 신고가 있었어요',
  String body = '김하준 · 7세 · 인하공전 도서관 앞',
  DateTime? createdAt,
  bool read = false,
}) {
  return AppNotification(
    id: id,
    kind: kind,
    caseId: caseId,
    title: title,
    body: body,
    createdAt:
        createdAt ?? DateTime.now().subtract(const Duration(minutes: 12)),
    read: read,
  );
}
