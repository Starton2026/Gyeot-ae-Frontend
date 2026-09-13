import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' hide Route;
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as kakao show Route;

import '../map/map_overlay_styles.dart';
import '../map/map_plan.dart';
import '../theme/app_colors.dart';

/// 보기만 하는 카카오맵. 홈의 주변 지도(F-1.3)와 상세의 이동 경로 미니 지도
/// (F-3.4)가 쓴다.
///
/// **손가락이 지도에 닿지 않는다.** 스크롤하는 화면 한가운데 움직이는 지도가
/// 있으면, 화면을 내리려던 손가락이 지도를 끌어 버린다. 그래서 `IgnorePointer`로
/// 덮고 SDK 제스처도 모두 끈다. 누르면 감싼 카드가 지도 탭(S5)으로 보낸다.
///
/// 카카오는 지도를 이미지로 주는 REST API가 없어 실제 지도를 띄운다.
/// [ready]가 false면(지도 키가 없거나 테스트) 회색 판만 둔다.
class StaticKakaoMap extends StatefulWidget {
  const StaticKakaoMap({required this.plan, required this.ready, super.key});

  final MapPlan plan;

  /// 카카오맵 SDK를 초기화했는가. `kakaoMapReadyProvider`의 값을 화면이 넘긴다.
  final bool ready;

  static const Key placeholderKey = Key('static_kakao_map_placeholder');

  @override
  State<StaticKakaoMap> createState() => _StaticKakaoMapState();
}

class _StaticKakaoMapState extends State<StaticKakaoMap> {
  /// 핀 주변에 남기는 여백. 카드가 작아서 지도 탭보다 좁게 잡는다.
  static const int _fitPadding = 48;

  final MapOverlayStyles _styles = MapOverlayStyles();
  final List<Poi> _pins = [];
  kakao.Route? _route;

  KakaoMapController? _controller;

  /// 마지막으로 그린 계획의 서명. 같으면 손대지 않는다.
  String? _drawnSignature;

  /// 그리기를 한 줄로 세운다. 계획이 연달아 바뀌면 그리기가 겹친다.
  Future<void> _queue = Future<void>.value();

  /// SDK가 오류를 알렸다(대개 키 인증). 흰 판 대신 회색 판으로 물러난다.
  bool _failed = false;

  @override
  void didUpdateWidget(covariant StaticKakaoMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.plan.signature != widget.plan.signature) _schedule();
  }

  Future<void> _onMapReady(KakaoMapController controller) async {
    _controller = controller;
    _drawnSignature = null;

    // IgnorePointer로 이미 막았지만, 플랫폼 뷰가 터치를 직접 받는 경우를 위해
    // SDK 쪽 제스처도 끈다.
    for (final gesture in GestureType.values) {
      if (gesture == GestureType.unknown) continue;
      try {
        await controller.setGesture(gesture, false);
      } on Object catch (error) {
        debugPrint('보기 전용 지도 제스처 끄기 실패($gesture): $error');
      }
    }

    _schedule();
  }

  void _onMapError(Object error) {
    debugPrint('카카오맵 오류(보기 전용): $error');
    if (mounted) setState(() => _failed = true);
  }

  void _schedule() {
    _queue = _queue
        .then((_) => _draw())
        .catchError((Object error) => debugPrint('보기 전용 지도 갱신 실패: $error'));
  }

  Future<void> _draw() async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final plan = widget.plan;
    if (plan.signature == _drawnSignature) return;
    _drawnSignature = plan.signature;

    for (final pin in _pins) {
      await controller.labelLayer.removePoi(pin);
    }
    _pins.clear();

    final route = _route;
    if (route != null) await controller.routeLayer.removeRoute(route);
    _route = null;

    if (plan.route.length >= 2) {
      _route = await controller.routeLayer.addRoute([
        for (final point in plan.route) LatLng(point.lat, point.lng),
      ], MapOverlayStyles.route);
    }

    for (final mark in plan.marks) {
      if (!mounted) return;
      final style = await _styleFor(mark, context);
      _pins.add(
        await controller.labelLayer.addPoi(
          LatLng(mark.at.lat, mark.at.lng),
          style: style,
        ),
      );
    }

    await controller.moveCamera(
      plan.fitMarks && plan.marks.length > 1
          ? CameraUpdate.fitMapPoints([
              for (final mark in plan.marks) LatLng(mark.at.lat, mark.at.lng),
            ], padding: _fitPadding)
          : CameraUpdate.newCenterPosition(
              LatLng(plan.center.lat, plan.center.lng),
              zoomLevel: plan.zoomLevel,
            ),
    );
  }

  Future<PoiStyle> _styleFor(MapMark mark, BuildContext context) {
    return switch (mark) {
      MissingMark(:final level) => _styles.missingPin(level, context: context),
      ReportMark(:final grade, :final routeIndex) => _styles.reportPin(
        grade,
        routeIndex: routeIndex,
        context: context,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ready || _failed) {
      return const ColoredBox(
        key: StaticKakaoMap.placeholderKey,
        color: AppColors.neutralGray,
        child: SizedBox.expand(),
      );
    }

    final center = widget.plan.center;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: KakaoMap(
          option: KakaoMapOption(
            position: LatLng(center.lat, center.lng),
            zoomLevel: widget.plan.zoomLevel,
          ),
          onMapReady: (controller) => unawaited(_onMapReady(controller)),
          onMapError: _onMapError,
        ),
      ),
    );
  }
}
