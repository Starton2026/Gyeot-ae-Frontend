import 'package:gyeotae/core/location/location_source.dart';

/// 네이티브 위치 서비스를 켜지 않는 [LocationSource].
///
/// 둘 다 null로 두면 권한을 거부했거나 위치 서비스가 꺼진 기기다.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({this.known, this.now});

  /// [lastKnown]이 돌려줄 좌표.
  LocationFix? known;

  /// [current]가 돌려줄 좌표.
  LocationFix? now;

  final List<String> calls = [];

  @override
  Future<LocationFix?> lastKnown() async {
    calls.add('lastKnown');
    return known;
  }

  @override
  Future<LocationFix?> current() async {
    calls.add('current');
    return now;
  }
}
