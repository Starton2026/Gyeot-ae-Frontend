import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// 알림을 눌러 들어온 사람이 어디로 가야 하는지.
///
/// 서버가 `data`에 실어 보낸다(`push_service.py`). 알림 본문은 안드로이드가
/// 알아서 그리고, 앱은 이 값만 읽어 화면을 연다.
@immutable
class PushOpen {
  const PushOpen({required this.type, required this.caseId});

  /// `missing`(주변 실종 신고) 또는 `resolved`(내 제보가 있던 사건이 끝남).
  final String type;

  final String caseId;

  /// 알 수 없는 알림이면 null. **모르는 값에 화면을 열지 않는다.**
  ///
  /// 서버가 나중에 다른 종류를 보내기 시작해도 앱이 엉뚱한 곳으로 튀지 않고
  /// 그냥 알림만 열리고 만다.
  static PushOpen? fromData(Map<String, dynamic> data) {
    final caseId = data['missing_id'];
    if (caseId is! String || caseId.isEmpty) return null;

    final type = data['type'];

    return PushOpen(type: type is String ? type : 'missing', caseId: caseId);
  }

  @override
  bool operator ==(Object other) =>
      other is PushOpen && other.type == type && other.caseId == caseId;

  @override
  int get hashCode => Object.hash(type, caseId);

  @override
  String toString() => 'PushOpen($type, $caseId)';
}

/// 앱이 켜져 있는 동안 도착한 알림.
///
/// **안드로이드는 앱이 앞에 떠 있으면 알림을 그려주지 않는다.** 그냥 두면
/// 제보하려고 앱을 열어 둔 사람만 알림을 못 받는 꼴이 된다. 그래서 이 값을
/// 받아 앱 안에서 직접 띄운다.
@immutable
class PushAlert {
  const PushAlert({required this.title, required this.body, this.open});

  final String title;
  final String body;

  /// 누르면 갈 곳. 모르는 알림이면 null.
  final PushOpen? open;

  static PushAlert? from(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return null;

    final title = notification.title;
    final body = notification.body;
    if (title == null || body == null) return null;

    return PushAlert(
      title: title,
      body: body,
      open: PushOpen.fromData(message.data),
    );
  }
}

/// 푸시 토큰과 알림 수신. 앱은 이 타입만 본다.
///
/// FCM을 직접 부르는 자리를 하나로 모아, 테스트와 Firebase가 없는 빌드에서
/// 갈아끼울 수 있게 한다.
abstract interface class PushMessaging {
  /// 알림 권한을 묻는다. 안드로이드 13+는 이때 시스템 팝업이 뜬다.
  Future<bool> requestPermission();

  /// 이 기기의 FCM 토큰. 권한이 없거나 못 받으면 null.
  Future<String?> token();

  /// 토큰이 새로 발급될 때마다. 서버에 다시 올려야 한다.
  Stream<String> tokenRefreshes();

  /// 알림을 눌러 앱이 **처음 뜬** 경우. 아니면 null.
  Future<PushOpen?> initialOpen();

  /// 앱이 떠 있는 동안 알림을 눌러 돌아온 경우.
  Stream<PushOpen> opens();

  /// 앱이 앞에 떠 있는 동안 도착한 알림. 앱이 직접 띄워야 한다.
  Stream<PushAlert> alerts();
}

/// 진짜 FCM.
class FirebasePushMessaging implements PushMessaging {
  const FirebasePushMessaging();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    final status = settings.authorizationStatus;

    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> tokenRefreshes() => _messaging.onTokenRefresh;

  @override
  Future<PushOpen?> initialOpen() async {
    final message = await _messaging.getInitialMessage();

    return message == null ? null : PushOpen.fromData(message.data);
  }

  @override
  Stream<PushOpen> opens() {
    return FirebaseMessaging.onMessageOpenedApp
        .map((message) => PushOpen.fromData(message.data))
        .where((open) => open != null)
        .cast<PushOpen>();
  }

  @override
  Stream<PushAlert> alerts() {
    return FirebaseMessaging.onMessage
        .map(PushAlert.from)
        .where((alert) => alert != null)
        .cast<PushAlert>();
  }
}

/// 아무것도 하지 않는 구현.
///
/// Firebase가 초기화되지 않은 자리(테스트, 설정 파일 없는 빌드)에서 쓴다.
/// 초기화 전에 `FirebaseMessaging.instance`를 만지면 앱이 그 자리에서 죽는데,
/// 알림이 없다고 앱이 안 뜨면 안 된다.
class SilentPushMessaging implements PushMessaging {
  const SilentPushMessaging();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> tokenRefreshes() => const Stream.empty();

  @override
  Future<PushOpen?> initialOpen() async => null;

  @override
  Stream<PushOpen> opens() => const Stream.empty();

  @override
  Stream<PushAlert> alerts() => const Stream.empty();
}

/// Firebase가 실제로 초기화됐는지. [Firebase.initializeApp]을 부른 뒤에만 참이다.
bool get firebaseReady => Firebase.apps.isNotEmpty;
