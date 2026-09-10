import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('저장된 토큰이 없으면 null을 돌려준다', () async {
    final storage = PrefsTokenStorage();

    expect(await storage.read(), isNull);
  });

  test('쓴 토큰을 다시 읽어올 수 있다', () async {
    final storage = PrefsTokenStorage();

    await storage.write('access-token-123');

    expect(await storage.read(), 'access-token-123');
  });

  test('clear를 호출하면 토큰이 지워진다', () async {
    final storage = PrefsTokenStorage();
    await storage.write('access-token-123');

    await storage.clear();

    expect(await storage.read(), isNull);
  });
}
