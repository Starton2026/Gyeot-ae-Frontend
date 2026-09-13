import 'dart:async';

import 'package:gyeotae/core/push/device_registrar.dart';
import 'package:gyeotae/core/push/push_messaging.dart';

/// 정해둔 토큰과 권한을 돌려주는 [PushMessaging].
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.allowed = true, this.fcmToken = 'fcm-token'});

  bool allowed;
  String? fcmToken;

  int permissionAsks = 0;

  final _refreshes = StreamController<String>.broadcast();
  final _opens = StreamController<PushOpen>.broadcast();
  final _alerts = StreamController<PushAlert>.broadcast();

  /// 토큰이 새로 발급된 척한다.
  void refresh(String token) {
    fcmToken = token;
    _refreshes.add(token);
  }

  /// 알림을 누른 척한다.
  void open(PushOpen open) => _opens.add(open);

  /// 앱이 켜져 있는 동안 알림이 온 척한다.
  void alert(PushAlert alert) => _alerts.add(alert);

  /// 알림을 눌러 앱이 처음 뜬 경우.
  PushOpen? initial;

  @override
  Future<bool> requestPermission() async {
    permissionAsks += 1;

    return allowed;
  }

  @override
  Future<String?> token() async => fcmToken;

  @override
  Stream<String> tokenRefreshes() => _refreshes.stream;

  @override
  Future<PushOpen?> initialOpen() async => initial;

  @override
  Stream<PushOpen> opens() => _opens.stream;

  @override
  Stream<PushAlert> alerts() => _alerts.stream;

  Future<void> dispose() async {
    await _refreshes.close();
    await _opens.close();
    await _alerts.close();
  }
}

/// 서버에 올린 값을 기억하는 [DeviceRegistrar].
class FakeDeviceRegistrar implements DeviceRegistrar {
  FakeDeviceRegistrar({this.error});

  /// 던질 예외. null이면 성공한다.
  Object? error;

  final List<({String token, double? lat, double? lng, double radiusKm})>
  calls = [];

  @override
  Future<void> register({
    required String pushToken,
    double? lat,
    double? lng,
    double radiusKm = 5,
  }) async {
    calls.add((token: pushToken, lat: lat, lng: lng, radiusKm: radiusKm));

    final failure = error;
    if (failure != null) throw failure;
  }
}
