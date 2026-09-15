import 'package:shared_preferences/shared_preferences.dart';

/// 액세스 토큰을 읽고 쓰는 저장소.
///
/// 테스트에서는 가짜 구현으로 갈아끼울 수 있다 (test/support 참고).
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// SharedPreferences 기반 구현. 앱 런타임에서 사용한다.
class PrefsTokenStorage implements TokenStorage {
  static const _key = 'access_token';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
