import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_source.dart';

/// "내 주변"의 기준이 되는 위치.
class AppLocation {
  const AppLocation({
    required this.lat,
    required this.lng,
    this.areaName,
    this.resolved = false,
  });

  final double lat;
  final double lng;

  /// 기기에서 **실제로 받은** 좌표다.
  ///
  /// false면 기본값이라 "내 주변"을 대충 정렬하는 데만 쓸 수 있다. 제보의
  /// 목격 위치처럼 사실로 기록되는 자리에는 쓰면 안 된다.
  final bool resolved;

  /// 제보에 실을 수 있는 좌표. 기본값이면 null.
  LocationFix? get fix => resolved ? (lat: lat, lng: lng) : null;

  /// 지명. **모를 수 있다.**
  ///
  /// 기기가 주는 것은 좌표뿐이고 그게 어느 동인지는 따로 물어봐야 한다
  /// (역지오코딩). 모르는 채로 "현재 위치 기준"이라고 적으면 어디를 말하는지
  /// 알 수 없으니, 지명을 아는 화면만 이 값을 쓴다.
  ///
  /// TODO(위치): 역지오코딩을 붙이면 여기를 채운다(F-4.3).
  final String? areaName;

  /// 위치 한 줄에 적는 이름. 지명을 모르면 "현재 위치".
  String get label => areaName ?? '현재 위치';

  /// 같은 좌표면 같은 값으로 본다.
  ///
  /// 위치를 여러 번 물어보면 같은 좌표가 다시 오는 일이 흔한데, 그때마다
  /// 새 객체로 알리면 홈·목록·지도가 아무 이유 없이 다시 그려진다.
  @override
  bool operator ==(Object other) {
    return other is AppLocation &&
        other.lat == lat &&
        other.lng == lng &&
        other.areaName == areaName &&
        other.resolved == resolved;
  }

  @override
  int get hashCode => Object.hash(lat, lng, areaName, resolved);
}

/// 지금 기준이 되는 위치. 기기 위치를 받으면 갈아낀다.
///
/// **동기로 읽힌다.** 위치를 아직 못 받았어도 화면은 곧바로 그려져야 한다.
/// 그래서 기본값으로 시작하고, 좌표가 들어오면 그때 다시 그린다. 이 provider를
/// `FutureProvider`로 두면 홈·목록·지도·제보창이 전부 로딩 상태를 다뤄야 한다.
///
/// **위치를 못 받는 것은 정상 경로다**(CLAUDE.md 규칙). 권한을 거부했거나
/// 위치 서비스가 꺼져 있으면 [fallback]으로 남는다. 거리 없이 긴급도순으로
/// 보여주면 된다.
class CurrentLocationNotifier extends Notifier<AppLocation> {
  /// 위치를 모를 때 쓰는 값. 시연용 좌표(인천 남동구 만수동)다.
  ///
  /// **시연 사건의 실종 지점과 겹치지 않는 자리로 잡는다.** 제보는 내 위치로
  /// 저장되기 때문에, 좌표가 같으면 방금 보낸 제보가 실종 지점 위에 얹히고
  /// 이동 경로가 출발점으로 되돌아오는 닫힌 고리로 그려진다.
  static const AppLocation fallback = AppLocation(
    lat: 37.4716,
    lng: 126.7538,
    areaName: '인천 남동구',
  );

  @override
  AppLocation build() {
    unawaited(locate());

    return fallback;
  }

  /// 기기에 위치를 물어본다. 받으면 [state]를 갈아낀다.
  Future<void> locate() async {
    final source = ref.read(locationSourceProvider);

    // 마지막으로 알려진 좌표를 먼저 쓴다. 정확한 좌표는 몇 초 걸리는데,
    // 그동안 시연용 좌표로 "내 주변"을 보여주면 엉뚱한 거리가 찍힌다.
    final known = await source.lastKnown();
    if (known != null && ref.mounted) state = _at(known);

    final now = await source.current();
    if (now != null && ref.mounted) state = _at(now);
  }

  /// 좌표만 알고 지명은 모른다. [AppLocation.areaName]을 비워둔다.
  AppLocation _at(LocationFix fix) {
    return AppLocation(lat: fix.lat, lng: fix.lng, resolved: true);
  }
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationNotifier, AppLocation>(
      CurrentLocationNotifier.new,
    );
