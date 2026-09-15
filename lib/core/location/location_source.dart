import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// 기기가 알려주는 좌표 한 쌍.
typedef LocationFix = ({double lat, double lng});

/// 기기 위치를 읽는다.
///
/// 화면이 `geolocator`를 직접 부르지 않는 이유는 `PhotoPicker`와 같다. 위젯
/// 테스트에서 네이티브 위치 서비스를 열 수 없고, 위치를 쓰는 화면이 여럿이다.
abstract interface class LocationSource {
  /// 마지막으로 알려진 좌표. 기기에 남아 있으면 바로 돌아온다.
  ///
  /// **권한을 묻지 않는다.** 이미 허용돼 있을 때만 값이 온다.
  Future<LocationFix?> lastKnown();

  /// 지금 좌표. 위성을 잡는 데 몇 초 걸릴 수 있다.
  ///
  /// [requestPermission]이 false면 **시스템 권한 팝업을 띄우지 않는다.** 아직
  /// 안 물어본 사람에게는 그냥 못 받은 것으로 둔다. 팝업은 사용자가 그러겠다고
  /// 누른 자리에서만 떠야 한다(온보딩 3장 · 제보창의 "다시 시도").
  ///
  /// **권한 거부는 정상 경로다**(CLAUDE.md 규칙). 예외를 던지지 않고 null을
  /// 돌려준다. 위치 서비스가 꺼져 있거나 시간이 초과돼도 마찬가지다. 부르는
  /// 쪽은 "못 받았다" 하나만 다루면 된다.
  Future<LocationFix?> current({bool requestPermission = false});
}

/// `geolocator`를 쓰는 실제 구현.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  /// 위치를 기다리는 한도. 실내에서는 끝내 안 잡히는 일이 있다.
  static const Duration _timeout = Duration(seconds: 8);

  @override
  Future<LocationFix?> lastKnown() async {
    try {
      if (!await _ensurePermission()) return null;

      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LocationFix?> current({bool requestPermission = false}) async {
    try {
      if (!await _ensurePermission(request: requestPermission)) return null;

      final position = await Geolocator.getCurrentPosition(
        // 최고 정확도는 실외에서도 오래 걸린다. 제보 위치는 몇십 미터
        // 오차로 충분하고, 늦게 오는 정확한 좌표보다 지금 오는 좌표가 낫다.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: _timeout,
        ),
      );

      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // 시간 초과, 위치 서비스 꺼짐, 플러그인 없음(테스트). 전부 "모른다"다.
      return null;
    }
  }

  /// 허용돼 있는지 본다. [request]일 때만 시스템 팝업을 띄운다.
  ///
  /// 한 번 거부하면 되돌리기 어려워서, 앱을 켜자마자 아무 설명 없이 묻는 것이
  /// 가장 나쁘다. 이유를 먼저 말한 자리에서만 묻는다.
  Future<bool> _ensurePermission({bool request = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

final locationSourceProvider = Provider<LocationSource>((ref) {
  return const GeolocatorLocationSource();
});
