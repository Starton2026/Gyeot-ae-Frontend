import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/map/kakao_map_init.dart';

void main() {
  test('키가 비어 있으면 초기화하지 않는다', () async {
    var called = 0;

    final initialized = await initKakaoMapSdk(
      key: '',
      initialize: (key) async => called++,
    );

    expect(initialized, isFalse);
    expect(called, 0);
  });

  test('키가 있으면 그 키로 초기화한다', () async {
    final keys = <String>[];

    final initialized = await initKakaoMapSdk(
      key: 'native-app-key',
      initialize: (key) async => keys.add(key),
    );

    expect(initialized, isTrue);
    expect(keys, ['native-app-key']);
  });
}
