import 'package:flutter/widgets.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

import '../../features/report/data/report.dart';
import '../theme/app_colors.dart';
import '../widgets/map_pin_icon.dart';
import '../widgets/map_report_pin_icon.dart';

/// 카카오맵에 올리는 핀·경로의 모양. 지도 탭(S5)과 홈·상세의 보기 전용 지도가
/// 같은 그림을 쓴다. 한 사건이 화면마다 다른 핀으로 찍히면 같은 사건으로 읽히지
/// 않는다.
///
/// 핀은 Flutter 위젯을 `KImage.fromWidget`으로 구워 올린다. 굽는 비용이 있어
/// **지도 하나당 이 객체를 하나 두고** 같은 모양은 한 번만 굽는다.
class MapOverlayStyles {
  final Map<String, PoiStyle> _cache = {};

  /// 이동 경로. 연결색이다 — 시민과 사건이 이어진 자리라는 뜻이고, 실종
  /// 위치(관심색)·제보 핀(신뢰색)과도 색이 겹치지 않는다.
  static final RouteStyle route = RouteStyle(
    AppColors.brandConnection,
    6,
    strokeColor: AppColors.white,
    strokeWidth: 2,
  );

  /// 실종 위치 핀. 끝이 좌표를 가리키도록 아래 가운데를 기준점으로 잡는다.
  Future<PoiStyle> missingPin(MapPinLevel level, {BuildContext? context}) {
    return _cached(
      'missing:${level.name}',
      () => MapPinIcon(level: level),
      level.canvasSize,
      const KPoint(0.5, 1),
      context,
    );
  }

  /// 제보 핀. 원이라 한가운데가 좌표다.
  Future<PoiStyle> reportPin(
    SimilarityGrade grade, {
    int? routeIndex,
    BuildContext? context,
  }) {
    return _cached(
      'report:${grade.wire}:${routeIndex ?? 0}',
      () => MapReportPinIcon(grade: grade, routeIndex: routeIndex),
      MapReportPinIcon.sizeOf(grade),
      const KPoint(0.5, 0.5),
      context,
    );
  }

  Future<PoiStyle> _cached(
    String key,
    Widget Function() build,
    Size size,
    KPoint anchor,
    BuildContext? context,
  ) async {
    final cached = _cache[key];
    if (cached != null) return cached;

    // 화면 배율만큼 크게 구워야 핀이 선명하다. 대신 네이티브가 밀도 배율을
    // 한 번 더 먹이지 않도록 applyDpScale을 끈다. 켜두면 3배율 기기에서
    // 핀이 3배로 커진다.
    final icon = await KImage.fromWidget(build(), size, context: context);

    return _cache[key] = PoiStyle(
      icon: icon,
      anchor: anchor,
      applyDpScale: false,
      // 나타날 때만 부드럽게 띄우고 사라질 때는 바로 지운다. 슬라이더를 되감을
      // 때 사라지는 애니메이션까지 기다리면 손보다 화면이 늦는다.
      iconTransition: const PoiTransition(exit: Transition.none),
    );
  }
}
