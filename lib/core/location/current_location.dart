import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "내 주변"의 기준이 되는 위치.
class AppLocation {
  const AppLocation({
    required this.lat,
    required this.lng,
    required this.label,
  });

  final double lat;
  final double lng;

  /// 화면에 적는 지역 이름. "인천 남동구 기준 · 긴급도순".
  final String label;
}

/// 지금은 데모용 고정 좌표(인천 남동구 구월동)다.
///
/// GPS를 붙일 때 이 provider 하나만 geolocator를 쓰는 것으로 바꾼다.
/// 그때도 **위치 권한 거부는 정상 경로**다. 기능을 막지 말고 이 기본값으로
/// 되돌려서 거리 없이 긴급도순으로만 보여준다.
final currentLocationProvider = Provider<AppLocation>((ref) {
  return const AppLocation(lat: 37.4491, lng: 126.7312, label: '인천 남동구');
});
