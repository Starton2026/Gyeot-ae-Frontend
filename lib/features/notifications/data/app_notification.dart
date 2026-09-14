import '../../../core/network/json.dart';
import '../../missing/data/missing_case.dart';

/// 알림 종류. 서버 `push_service.py`가 보내는 세 가지다.
enum NotificationKind {
  /// 내 주변에서 실종 신고가 들어왔다.
  missing,

  /// 내가 등록한 사건에 목격 제보가 들어왔다.
  report,

  /// 내가 제보한 사건의 사람을 찾았다.
  resolved,

  /// 앱이 모르는 종류. 서버가 나중에 새 종류를 보내도 깨지지 않게 둔다.
  unknown;

  static NotificationKind fromJson(Object? value) {
    return switch (value) {
      'missing' => NotificationKind.missing,
      'report' => NotificationKind.report,
      'resolved' => NotificationKind.resolved,
      _ => NotificationKind.unknown,
    };
  }
}

/// 알림함 한 줄. `GET /me/notifications`.
///
/// 푸시로 받았던 것과 같은 제목·본문이다. 서버가 보낼 때 받는 사람마다 적어
/// 두기 때문에, 폰이 꺼져 있어 푸시를 놓쳤어도 여기에는 남는다.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.caseId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.reportId,
    this.missingThumbnail,
    this.missingStatus,
  });

  final String id;
  final NotificationKind kind;

  /// 누르면 여는 사건.
  final String caseId;

  /// 목격 제보 알림이면 그 제보.
  final String? reportId;

  final String title;
  final String body;
  final DateTime createdAt;

  /// 알림함을 연 적이 있는지. 여는 순간 서버에서는 전부 읽음이 된다.
  final bool read;

  /// 서버가 준 상대 경로. 사건이 지워졌으면 null.
  final String? missingThumbnail;

  final CaseStatus? missingStatus;

  AppNotification markedRead() {
    return AppNotification(
      id: id,
      kind: kind,
      caseId: caseId,
      reportId: reportId,
      title: title,
      body: body,
      createdAt: createdAt,
      read: true,
      missingThumbnail: missingThumbnail,
      missingStatus: missingStatus,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: jsonString(json['id']),
      kind: NotificationKind.fromJson(json['type']),
      caseId: jsonString(json['missing_id']),
      reportId: jsonStringOrNull(json['report_id']),
      title: jsonString(json['title']),
      body: jsonString(json['body']),
      createdAt: jsonDate(json['created_at']),
      read: jsonBool(json['read']),
      missingThumbnail: jsonStringOrNull(json['missing_thumbnail']),
      missingStatus: json['missing_status'] == null
          ? null
          : CaseStatus.fromJson(json['missing_status']),
    );
  }
}

/// 알림함 한 묶음.
class NotificationInbox {
  const NotificationInbox({
    required this.count,
    required this.unreadCount,
    required this.items,
  });

  const NotificationInbox.empty()
    : count = 0,
      unreadCount = 0,
      items = const [];

  /// 전체 건수. 서버는 최신 50건만 준다.
  final int count;

  /// 안 읽은 수. 상단바 알림 버튼의 점이 이 값을 본다.
  final int unreadCount;

  final List<AppNotification> items;

  bool get isEmpty => items.isEmpty;

  /// 전부 읽었다고 서버에 알린 뒤의 묶음. 서버와 같은 모양으로 맞춘다.
  ///
  /// 무엇이 새로 왔는지 강조하는 것은 알림 화면이 연 순간을 기억해서 한다.
  NotificationInbox markedRead() {
    return NotificationInbox(
      count: count,
      unreadCount: 0,
      items: [for (final item in items) item.markedRead()],
    );
  }

  factory NotificationInbox.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return NotificationInbox(
      count: jsonInt(json['count']),
      unreadCount: jsonInt(json['unread_count']),
      items: (items is List ? items : const [])
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .where((item) => item.caseId.isNotEmpty)
          .toList(growable: false),
    );
  }
}
