import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// 이 설치본을 가리키는 값. 서버에 `X-Device-Hash`로 나간다.
///
/// **로그인 없이 제보한 사람을 구분하는 유일한 단서다.** 서버는 이 값으로
/// 세 가지를 한다.
/// - 게스트 제보 횟수 제한 (사건 1건당 10분에 3회)
/// - 카카오 로그인 시 그 전에 게스트로 보낸 제보를 계정에 귀속
/// - 로그인 안 한 사람의 "내 제보" 조회
///
/// 안 보내면 서버가 모두를 `anonymous` 한 덩어리로 묶는다. 데모에서 여러 대로
/// 제보하면 네 번째부터 429가 난다.
///
/// **기기 고유값이 아니라 그냥 난수다.** 광고 ID나 하드웨어 식별자를 읽지
/// 않는다. 앱을 지우면 사라지고, 그러면 그 전 제보와의 연결도 끊긴다.
abstract class DeviceIdStorage {
  /// 저장된 값을 주고, 없으면 만들어 저장한다.
  Future<String> read();
}

class PrefsDeviceIdStorage implements DeviceIdStorage {
  static const _key = 'device_hash';

  /// 요청마다 SharedPreferences를 열지 않는다.
  String? _cached;

  @override
  Future<String> read() async {
    final cached = _cached;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) return _cached = saved;

    final created = _newId();
    await prefs.setString(_key, created);

    return _cached = created;
  }

  static String _newId() {
    final random = Random.secure();

    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
