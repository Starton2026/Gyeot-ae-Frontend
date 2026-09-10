import 'package:gyeotae/core/storage/token_storage.dart';

/// 테스트용 토큰 저장소. 메모리에만 담아둔다.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
