import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' hide Route;
import 'package:kakao_map_sdk/kakao_map_sdk.dart' as kakao show Route;

import '../../../core/location/current_location.dart';
import '../../../core/map/kakao_map_init.dart';
import '../../../core/theme/app_colors.dart';
import '../../missing/data/missing_case.dart';
import '../../report/data/report.dart';
import '../../report/data/report_repository.dart';
import 'map_providers.dart';
import 'widgets/map_case_carousel.dart';
import 'widgets/map_case_select_bar.dart';
import 'widgets/map_overlay_chrome.dart';
import 'widgets/map_pin_icon.dart';
import 'widgets/map_report_pin_icon.dart';
import 'widgets/map_report_sheet.dart';
import 'widgets/map_route_panel.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/map_unavailable_view.dart';

/// 지도(S5). 로그인 없이 볼 수 있다.
///
/// 한 화면에 두 모드가 있고 [selectedMapCaseProvider] 하나로 갈린다.
///
/// - **전체 보기** — 실종 위치 핀만. 여러 사건의 경로를 겹치면 선이 엉켜
///   아무것도 읽히지 않는다.
/// - **사건 선택** — 그 사건의 제보 핀과 이동 경로, 그리고 시간 슬라이더.
///
/// 모드를 바꿔도 지도 자체는 그대로 두고 오버레이만 갈아 끼운다. 플랫폼 뷰를
/// 다시 만들면 느리고, 안드로이드에서는 표면이 검게 날아간다.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({this.initialCaseId, super.key});

  /// `/map?case=<id>`로 들어왔을 때 바로 그 사건을 편다. 상세(S3)의 미니
  /// 지도가 이 경로로 보낸다.
  final String? initialCaseId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  /// 여러 사건이 한눈에 들어오는 배율.
  static const int _overviewZoom = 13;

  /// 사건 하나를 볼 때의 배율.
  static const int _caseZoom = 15;

  final PageController _pageController = PageController(viewportFraction: 0.78);

  KakaoMapController? _controller;

  /// 지도에 올라가 있는 핀. 사건 id 또는 제보 id로 찾는다.
  final Map<String, Poi> _pins = {};

  /// 각 핀이 어떤 그림으로 그려져 있는지. 등급이 바뀌면 다시 그려야 한다.
  final Map<String, String> _pinStyleKeys = {};

  /// 지도에 올라가 있는 경로선.
  final List<kakao.Route> _routes = [];

  /// 핀 스타일 캐시. 이미지를 굽는 비용이 있어 한 번만 만들어 돌려 쓴다.
  final Map<String, PoiStyle> _styles = {};

  /// 오버레이 갱신을 한 줄로 세운다. 슬라이더를 끌면 갱신이 겹친다.
  Future<void> _overlayQueue = Future<void>.value();

  /// 마지막으로 지도에 그린 상태. 같으면 다시 그리지 않는다.
  String? _drawnSignature;

  /// 마지막으로 그린 경로의 점 목록.
  String? _drawnRouteKey;

  /// SDK가 알려준 오류. 대개 네이티브 키 인증 실패다.
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _applyInitialCase(null);
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 지도 탭에 이미 들어와 있는 상태에서 `/map?case=`로 들어올 수 있다.
    // 그때는 화면이 새로 만들어지지 않으므로 여기서 받아야 한다.
    _applyInitialCase(oldWidget.initialCaseId);
  }

  void _applyInitialCase(String? previous) {
    final caseId = widget.initialCaseId;
    if (caseId == null || caseId == previous) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(selectedMapCaseProvider.notifier).select(caseId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMapError(Object error) {
    // 흰 화면만 남으면 원인을 알 수 없다. 콘솔과 화면 둘 다에 남긴다.
    debugPrint('카카오맵 오류: $error');

    if (mounted) setState(() => _mapError = error.toString());
  }

  Future<void> _onMapReady(KakaoMapController controller) async {
    _controller = controller;
    _drawnSignature = null;

    _scheduleDraw();
  }

  // ── 오버레이 ────────────────────────────────────────────────

  /// 지도에 무엇을 올릴지 정한다. 실제로 그리기 전에 계획만 세운다.
  ///
  /// 계획을 한 줄로 요약해 지난번과 비교하면, **바뀐 것이 없을 때 아예 손대지
  /// 않는다.** 시간 슬라이더는 1픽셀만 움직여도 값이 바뀌지만 화면에 보이는
  /// 것은 제보 시각을 지날 때만 바뀐다. 매번 다시 그리면 선이 반짝인다.
  ({List<_PinPlan> pins, List<LatLng> route}) _planOverlays() {
    final caseId = ref.read(selectedMapCaseProvider);

    if (caseId == null) {
      final cases = ref.read(mapCasesProvider).value ?? const [];

      return (
        pins: [
          for (final summary in cases)
            _missingPin(
              id: summary.id,
              position: LatLng(summary.lastLat, summary.lastLng),
              level: MapPinLevel.of(summary.elapsedMinutes),
              onClick: () => _focusCase(summary.id),
            ),
        ],
        route: const [],
      );
    }

    final bundle = ref.read(caseReportsProvider(caseId)).value;
    if (bundle == null) return (pins: const [], route: const []);

    final view = MapCaseView.of(
      bundle,
      highOnly: ref.read(mapHighOnlyProvider),
      cursor: ref.read(mapTimeCursorProvider),
    );
    final origin = bundle.origin;

    return (
      pins: [
        if (origin != null)
          _missingPin(
            id: 'origin',
            position: LatLng(origin.lat, origin.lng),
            level: MapPinLevel.golden,
          ),
        for (final report in view.locatedReports)
          (
            id: report.id,
            position: LatLng(report.lat!, report.lng!),
            styleKey:
                'report:${report.grade.wire}:${report.routeIndex ?? 0}',
            style: () => _reportPinStyle(report),
            onClick: () => showMapReportSheet(context, report: report),
          ),
      ],
      // 경로는 실종 지점에서 시작해 시간순으로 잇는다(설계 결정 5번).
      route: [
        if (origin != null) LatLng(origin.lat, origin.lng),
        for (final report in view.pathReports)
          LatLng(report.lat!, report.lng!),
      ],
    );
  }

  _PinPlan _missingPin({
    required String id,
    required LatLng position,
    required MapPinLevel level,
    VoidCallback? onClick,
  }) {
    return (
      id: id,
      position: position,
      styleKey: 'missing:${level.name}',
      style: () => _missingPinStyle(level),
      onClick: onClick,
    );
  }

  void _scheduleDraw() {
    _overlayQueue = _overlayQueue
        .then((_) => _draw())
        .catchError((Object error) => debugPrint('지도 오버레이 갱신 실패: $error'));
  }

  Future<void> _draw() async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final plan = _planOverlays();
    final signature = [
      for (final pin in plan.pins) '${pin.id}@${pin.styleKey}',
      '|',
      for (final point in plan.route) '${point.latitude},${point.longitude}',
    ].join(';');

    if (signature == _drawnSignature) return;
    _drawnSignature = signature;

    await _applyPins(controller, plan.pins);
    await _applyRoute(controller, plan.route);
  }

  /// 있던 핀은 그대로 두고 없어진 것만 지운다. 다 지우고 다시 그리면 바뀌지
  /// 않은 핀까지 깜빡인다.
  Future<void> _applyPins(
    KakaoMapController controller,
    List<_PinPlan> plans,
  ) async {
    final wanted = {for (final plan in plans) plan.id: plan};

    for (final entry in _pins.entries.toList()) {
      final plan = wanted[entry.key];
      // 같은 자리라도 등급이 바뀌면 그림이 달라지므로 다시 그린다.
      if (plan != null && plan.styleKey == _pinStyleKeys[entry.key]) continue;

      await controller.labelLayer.removePoi(entry.value);
      _pins.remove(entry.key);
      _pinStyleKeys.remove(entry.key);
    }

    for (final plan in plans) {
      if (_pins.containsKey(plan.id)) continue;

      _pins[plan.id] = await controller.labelLayer.addPoi(
        plan.position,
        style: await plan.style(),
        onClick: plan.onClick,
      );
      _pinStyleKeys[plan.id] = plan.styleKey;
    }
  }

  /// 경로는 점 하나만 달라져도 선 전체를 다시 그려야 한다. 대신 **점 목록이
  /// 같으면 건드리지 않는다.**
  Future<void> _applyRoute(
    KakaoMapController controller,
    List<LatLng> points,
  ) async {
    final key = [
      for (final point in points) '${point.latitude},${point.longitude}',
    ].join(';');
    if (key == _drawnRouteKey) return;
    _drawnRouteKey = key;

    for (final route in _routes) {
      await controller.routeLayer.removeRoute(route);
    }
    _routes.clear();

    if (points.length < 2) return;

    _routes.add(
      await controller.routeLayer.addRoute(
        points,
        // 경로는 연결색이다. 시민과 사건이 이어진 자리라는 뜻이고, 실종
        // 위치(관심색)·제보 핀(신뢰색)과도 색이 겹치지 않는다.
        RouteStyle(
          AppColors.brandConnection,
          6,
          strokeColor: AppColors.white,
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// 실종 위치 핀 스타일. 끝이 좌표를 가리키도록 아래 가운데를 기준점으로 잡는다.
  Future<PoiStyle> _missingPinStyle(MapPinLevel level) {
    return _cachedStyle(
      'missing:${level.name}',
      () => MapPinIcon(level: level),
      level.canvasSize,
      const KPoint(0.5, 1),
    );
  }

  /// 제보 핀 스타일. 원이라 한가운데가 좌표다.
  Future<PoiStyle> _reportPinStyle(Report report) {
    return _cachedStyle(
      'report:${report.grade.wire}:${report.routeIndex ?? 0}',
      () => MapReportPinIcon(
        grade: report.grade,
        routeIndex: report.routeIndex,
      ),
      MapReportPinIcon.sizeOf(report.grade),
      const KPoint(0.5, 0.5),
    );
  }

  Future<PoiStyle> _cachedStyle(
    String key,
    Widget Function() build,
    Size size,
    KPoint anchor,
  ) async {
    final cached = _styles[key];
    if (cached != null) return cached;

    // 화면 배율만큼 크게 구워야 핀이 선명하다. 대신 네이티브가 밀도 배율을
    // 한 번 더 먹이지 않도록 applyDpScale을 끈다. 켜두면 3배율 기기에서
    // 핀이 3배로 커진다.
    final icon = await KImage.fromWidget(
      build(),
      size,
      context: mounted ? context : null,
    );

    return _styles[key] = PoiStyle(
      icon: icon,
      anchor: anchor,
      applyDpScale: false,
      // 나타날 때만 부드럽게 띄우고 사라질 때는 바로 지운다. 슬라이더를 되감을
      // 때 사라지는 애니메이션까지 기다리면 손보다 화면이 늦는다.
      iconTransition: const PoiTransition(exit: Transition.none),
    );
  }


  // ── 조작 ────────────────────────────────────────────────────

  /// 핀을 누르면 카드가 따라오고, 카드를 넘기면 지도가 따라간다.
  void _focusCase(String caseId) {
    final cases = ref.read(mapCasesProvider).value ?? const [];
    final index = cases.indexWhere((item) => item.id == caseId);
    if (index < 0) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    final cases = ref.read(mapCasesProvider).value ?? const [];
    if (index < 0 || index >= cases.length) return;

    final summary = cases[index];
    _moveCamera(LatLng(summary.lastLat, summary.lastLng), _caseZoom);
  }

  void _moveToMyLocation() {
    final location = ref.read(currentLocationProvider);

    _moveCamera(LatLng(location.lat, location.lng), _overviewZoom);
  }

  void _moveCamera(LatLng position, int zoomLevel) {
    _controller?.moveCamera(
      CameraUpdate.newCenterPosition(position, zoomLevel: zoomLevel),
      animation: const CameraAnimation(240),
    );
  }

  /// 사건을 펴면 경로 전체가 화면에 들어오게 맞춘다.
  void _fitCase(ReportOrigin? origin, MapCaseView view) {
    final points = [
      if (origin != null) LatLng(origin.lat, origin.lng),
      for (final report in view.locatedReports)
        LatLng(report.lat!, report.lng!),
    ];
    if (points.isEmpty) return;

    if (points.length == 1) {
      _moveCamera(points.first, _caseZoom);
      return;
    }

    _controller?.moveCamera(
      CameraUpdate.fitMapPoints(points, padding: 90),
      animation: const CameraAnimation(280),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(kakaoMapReadyProvider);
    final location = ref.watch(currentLocationProvider);
    final caseId = ref.watch(selectedMapCaseProvider);
    final casesAsync = ref.watch(mapCasesProvider);
    final cases = casesAsync.value ?? const <MissingCaseSummary>[];

    final bundle = caseId == null
        ? null
        : ref.watch(caseReportsProvider(caseId)).value;
    final view = bundle == null
        ? null
        : MapCaseView.of(
            bundle,
            highOnly: ref.watch(mapHighOnlyProvider),
            cursor: ref.watch(mapTimeCursorProvider),
          );

    // 그릴 것이 바뀌었으면 프레임이 끝난 뒤에 지도에 반영한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleDraw();
    });

    // 사건을 막 폈으면 경로 전체가 보이게 카메라를 맞춘다.
    ref.listen(selectedMapCaseProvider, (previous, next) {
      if (next == null) {
        _moveToMyLocation();
        return;
      }

      final current = ref.read(caseReportsProvider(next)).value;
      if (current != null) {
        _fitCase(
          current.origin,
          MapCaseView.of(current, highOnly: ref.read(mapHighOnlyProvider)),
        );
      }
    });

    return Scaffold(
      // 키보드가 올라올 때 화면을 줄이지 않는다. 줄이면 지도(플랫폼 뷰)가 다시
      // 레이아웃되면서 GL 표면이 검게 날아가고 프레임이 크게 밀린다.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          if (!ready)
            const MapUnavailableView(reason: MapUnavailableReason.noKey)
          else ...[
            KakaoMap(
              option: KakaoMapOption(
                position: LatLng(location.lat, location.lng),
                zoomLevel: _overviewZoom,
              ),
              onMapReady: _onMapReady,
              onMapError: _onMapError,
            ),
            if (_mapError != null)
              MapUnavailableView(
                reason: MapUnavailableReason.authFailed,
                detail: _mapError,
              ),
          ],
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: caseId == null
                      ? _OverviewTop(cases: cases)
                      : _SelectedTop(caseId: caseId, cases: cases),
                ),
                // 가운데는 비워 둔다. 지도를 직접 만질 수 있어야 한다.
                const Spacer(),
                if (caseId == null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: MapOverlayChrome(
                      hint: _hint(casesAsync, location.areaName, cases.length),
                      onMyLocation: _moveToMyLocation,
                    ),
                  ),
                  if (cases.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 0, 12),
                      child: MapCaseCarousel(
                        cases: cases,
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        onTapCase: (summary) => ref
                            .read(selectedMapCaseProvider.notifier)
                            .select(summary.id),
                      ),
                    ),
                ] else if (view != null)
                  MapRoutePanel(
                    view: view,
                    highOnly: ref.watch(mapHighOnlyProvider),
                    onHighOnlyChanged:
                        ref.read(mapHighOnlyProvider.notifier).set,
                    onCursorChanged: ref.read(mapTimeCursorProvider.notifier).set,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체 보기의 상단. 검색과 구분 칩.
class _OverviewTop extends ConsumerWidget {
  const _OverviewTop({required this.cases});

  final List<MissingCaseSummary> cases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MapSearchBar(
      filter: ref.watch(mapQueryProvider).filter,
      totalCount: cases.length,
      onKeywordChanged: ref.read(mapQueryProvider.notifier).setKeyword,
      onFilterChanged: ref.read(mapQueryProvider.notifier).setFilter,
    );
  }
}

/// 사건 선택 모드의 상단. 지금 보고 있는 사건.
class _SelectedTop extends ConsumerWidget {
  const _SelectedTop({required this.caseId, required this.cases});

  final String caseId;
  final List<MissingCaseSummary> cases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = cases.where((item) => item.id == caseId).firstOrNull;
    if (summary == null) return const SizedBox.shrink();

    return MapCaseSelectBar(
      summary: summary,
      onTap: () => ref.read(selectedMapCaseProvider.notifier).select(null),
    );
  }
}

/// 지도 아래에 붙는 한 줄. 지금 무엇을 보고 있는지 알린다.
String _hint(
  AsyncValue<List<MissingCaseSummary>> cases,
  String? areaName,
  int count,
) {
  if (cases.isLoading && cases.value == null) return '사건을 불러오는 중';
  if (cases.hasError && cases.value == null) return '사건을 불러오지 못했어요';
  if (count == 0) return '조건에 맞는 사건이 없어요';

  // 지명을 모르면 "현재 위치 기준"이라고 적어봐야 어디인지 알 수 없다.
  if (areaName == null) return '진행 중 $count건 · 긴급도순';

  return '$areaName 기준 진행 중 $count건 · 긴급도순';
}

/// 지도에 올릴 핀 하나의 계획.
///
/// 그리기 전에 계획으로 만들어 두면, 지난번 계획과 비교해서 **달라진 것만**
/// 지도에 손댈 수 있다.
typedef _PinPlan = ({
  String id,
  LatLng position,
  String styleKey,
  Future<PoiStyle> Function() style,
  VoidCallback? onClick,
});
