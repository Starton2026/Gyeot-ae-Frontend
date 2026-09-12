import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

import '../../../core/location/current_location.dart';
import '../../../core/map/kakao_map_init.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../missing/data/missing_case.dart';
import 'map_providers.dart';
import 'widgets/map_case_carousel.dart';
import 'widgets/map_overlay_chrome.dart';
import 'widgets/map_pin_icon.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/map_unavailable_view.dart';

/// 지도 · 전체 보기(S5). 로그인 없이 볼 수 있다.
///
/// **실종 위치 핀만 그린다.** 제보 핀과 이동 경로는 사건 하나를 골랐을 때만
/// 의미가 생긴다. 여러 사건의 경로를 겹치면 선이 엉켜 아무것도 읽히지 않는다.
///
/// 지도는 탭이라 하단 네비게이션을 유지한다.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

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

  /// 지도에 올라가 있는 핀. 사건 id로 찾는다.
  final Map<String, Poi> _pins = {};

  /// 단계별 핀 스타일. 이미지를 굽는 비용이 있어 한 번만 만들어 돌려 쓴다.
  final Map<MapPinLevel, PoiStyle> _pinStyles = {};

  /// 핀 갱신을 한 줄로 세운다. 검색어를 빠르게 고치면 갱신이 겹친다.
  Future<void> _pinQueue = Future<void>.value();

  /// SDK가 알려준 오류. 대개 네이티브 키 인증 실패다.
  String? _mapError;

  void _onMapError(Object error) {
    // 흰 화면만 남으면 원인을 알 수 없다. 콘솔과 화면 둘 다에 남긴다.
    debugPrint('카카오맵 오류: $error');

    if (mounted) setState(() => _mapError = error.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onMapReady(KakaoMapController controller) async {
    _controller = controller;

    final cases = ref.read(mapCasesProvider).value;
    if (cases != null) _schedulePinSync(cases);
  }

  void _schedulePinSync(List<MissingCaseSummary> cases) {
    _pinQueue = _pinQueue
        .then((_) => _syncPins(cases))
        .catchError((Object error) => debugPrint('지도 핀 갱신 실패: $error'));
  }

  /// 지도 위의 핀을 목록과 맞춘다. 이미 있는 핀은 그대로 두고 차이만 반영한다.
  Future<void> _syncPins(List<MissingCaseSummary> cases) async {
    final controller = _controller;
    if (controller == null) return;

    final ids = cases.map((item) => item.id).toSet();

    for (final entry in _pins.entries.toList()) {
      if (ids.contains(entry.key)) continue;

      await controller.labelLayer.removePoi(entry.value);
      _pins.remove(entry.key);
    }

    for (final summary in cases) {
      if (_pins.containsKey(summary.id)) continue;

      final style = await _styleFor(MapPinLevel.of(summary.elapsedMinutes));
      _pins[summary.id] = await controller.labelLayer.addPoi(
        LatLng(summary.lastLat, summary.lastLng),
        style: style,
        onClick: () => _focusCase(summary.id),
      );
    }
  }

  /// 핀 그림을 위젯으로 그려서 굽는다. 단계마다 한 장이면 된다.
  Future<PoiStyle> _styleFor(MapPinLevel level) async {
    final cached = _pinStyles[level];
    if (cached != null) return cached;

    // 화면 배율만큼 크게 구워야 핀이 선명하다. 대신 네이티브가 밀도 배율을
    // 한 번 더 먹이지 않도록 applyDpScale을 끈다. 켜두면 3배율 기기에서
    // 핀이 3배로 커진다.
    final icon = await KImage.fromWidget(
      MapPinIcon(level: level),
      level.canvasSize,
      context: mounted ? context : null,
    );
    // 핀 끝이 좌표를 가리키도록 그림의 아래 가운데를 기준점으로 잡는다.
    final style = PoiStyle(
      icon: icon,
      anchor: const KPoint(0.5, 1),
      applyDpScale: false,
    );

    return _pinStyles[level] = style;
  }

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
    ref.read(selectedMapCaseProvider.notifier).select(summary.id);
    _moveCamera(LatLng(summary.lastLat, summary.lastLng), _caseZoom);
  }

  void _moveToMyLocation() {
    final location = ref.read(currentLocationProvider);

    ref.read(selectedMapCaseProvider.notifier).select(null);
    _moveCamera(LatLng(location.lat, location.lng), _overviewZoom);
  }

  void _moveCamera(LatLng position, int zoomLevel) {
    _controller?.moveCamera(
      CameraUpdate.newCenterPosition(position, zoomLevel: zoomLevel),
      animation: const CameraAnimation(320),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(kakaoMapReadyProvider);
    final query = ref.watch(mapQueryProvider);
    final location = ref.watch(currentLocationProvider);
    final casesAsync = ref.watch(mapCasesProvider);
    final cases = casesAsync.value ?? const <MissingCaseSummary>[];

    ref.listen(mapCasesProvider, (previous, next) {
      final items = next.value;
      if (items != null) _schedulePinSync(items);
    });

    return Scaffold(
      // 키보드가 올라올 때 화면을 줄이지 않는다. 줄이면 지도(플랫폼 뷰)가 다시
      // 레이아웃되면서 GL 표면이 검게 날아가고 프레임이 크게 밀린다.
      // 검색창은 위에 있어서 키보드가 가리지도 않는다.
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: AppBottomNav(
        current: AppTab.map,
        onSelect: (tab) => context.go(tab.path!),
      ),
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
                  child: MapSearchBar(
                    filter: query.filter,
                    totalCount: cases.length,
                    onKeywordChanged: ref
                        .read(mapQueryProvider.notifier)
                        .setKeyword,
                    onFilterChanged: ref
                        .read(mapQueryProvider.notifier)
                        .setFilter,
                  ),
                ),
                // 가운데는 비워 둔다. 지도를 직접 만질 수 있어야 한다.
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: MapOverlayChrome(
                    hint: _hint(casesAsync, location.label, cases.length),
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
                      // TODO(S5-2): 사건 선택 모드가 생기면 그쪽으로 보낸다.
                      onTapCase: (summary) =>
                          context.push(AppRoute.missingDetail(summary.id)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 지도 아래에 붙는 한 줄. 지금 무엇을 보고 있는지 알린다.
String _hint(
  AsyncValue<List<MissingCaseSummary>> cases,
  String locationLabel,
  int count,
) {
  if (cases.isLoading && cases.value == null) return '사건을 불러오는 중';
  if (cases.hasError && cases.value == null) return '사건을 불러오지 못했어요';
  if (count == 0) return '조건에 맞는 사건이 없어요';

  return '$locationLabel 기준 진행 중 $count건 · 긴급도순';
}
