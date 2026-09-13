import 'package:gyeotae/core/storage/device_id.dart';

/// 테스트용 기기 식별자. 정해진 값을 그대로 돌려준다.
///
/// 진짜 구현은 SharedPreferences를 읽어서 바인딩이 필요하다.
class InMemoryDeviceIdStorage implements DeviceIdStorage {
  InMemoryDeviceIdStorage([this.id = 'test-device']);

  final String id;

  @override
  Future<String> read() async => id;
}
