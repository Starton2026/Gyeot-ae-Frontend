import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart' hide Route;

import '../../../core/location/current_location.dart';
import '../../../core/location/location_source.dart';
import '../../../core/map/kakao_map_init.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/map_unavailable_view.dart';
import '../data/address_lookup.dart';

/// 마지막 목격 위치 고르기(F-7.7). 고른 좌표를 `pop`으로 돌려준다.
///
/// **핀은 가운데에 고정하고 지도를 끈다.** 작은 핀을 손가락으로 집어 옮기는
/// 것보다 지도를 밀어 핀 아래에 맞추는 편이 떨리는 손으로도 정확하다.
class RegisterLocationScreen extends ConsumerStatefulWidget {
  const RegisterLocationScreen({this.initial, super.key});

  /// 처음 비출 자리. 폼에 이미 위치가 있으면 그 자리다.
  final LocationFix? initial;

  static const Key confirmKey = Key('register_location_confirm');

  @override
  ConsumerState<RegisterLocationScreen> createState() =>
      _RegisterLocationScreenState();
}

class _RegisterLocationScreenState
    extends ConsumerState<RegisterLocationScreen> {
  /// 동네가 읽히는 배율.
  static const int _zoom = 16;

  /// 지금 핀 아래의 좌표. 지도가 없으면 처음 자리 그대로다.
  LocationFix? _center;

  /// 핀 아래의 주소. 찾는 중이면 null.
  String? _address;
  bool _looking = false;
  String? _mapError;

  @override
  void initState() {
    super.initState();

    // 폼에 위치가 없으면 기기 위치에서 시작한다. 기기 위치도 모르면 시연용
    // 기본 좌표로 **카메라만** 둔다 — 보호자가 밀어서 맞출 출발점일 뿐이다.
    final location = ref.read(currentLocationProvider);
    _center = widget.initial ?? (lat: location.lat, lng: location.lng);
    _looking = true;
    unawaited(_lookup(_center!));
  }

  Future<void> _lookup(LocationFix at) async {
    final address = await ref
        .read(addressLookupProvider)
        .addressAt(lat: at.lat, lng: at.lng);
    if (!mounted || _center != at) return;

    setState(() {
      _looking = false;
      _address = address;
    });
  }

  void _onCameraMoveEnd(CameraPosition position, GestureType gesture) {
    final at = (
      lat: position.position.latitude,
      lng: position.position.longitude,
    );
    setState(() {
      _center = at;
      _looking = true;
    });
    unawaited(_lookup(at));
  }

  void _onMapError(Object error) {
    debugPrint('카카오맵 오류(위치 고르기): $error');
    if (mounted) setState(() => _mapError = error.toString());
  }

  String get _addressLine {
    if (_looking) return '주소를 찾는 중';

    return _address ?? '주소를 찾지 못했어요. 핀 위치로 등록됩니다.';
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(kakaoMapReadyProvider);
    final start = widget.initial ?? _center!;

    // 지도를 못 띄우면 보호자가 핀을 옮길 수 없다. 그때 확정할 수 있는 자리는
    // 폼에 이미 있던 위치나 기기가 실제로 알려준 위치뿐이다. 시연용 기본 좌표를
    // 실종 위치로 확정하면 엉뚱한 동네에 사건이 생긴다.
    final canConfirm =
        ready ||
        widget.initial != null ||
        ref.watch(currentLocationProvider).resolved;

    return Scaffold(
      // 키보드가 올라와도 줄이지 않는다. 지도는 플랫폼 뷰라, 크기를 바꾸는
      // 중에 화면이 닫히며 정리되면 엔진이 죽는다(SurfaceProducer NPE —
      // 폼으로 돌아가며 입력칸에 포커스가 되돌아가는 순간 실기기에서 났다).
      // 지도 탭(MapScreen)도 같은 이유로 막아 두었다.
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar.modal('위치 고르기', onClose: () => context.pop()),
      body: Stack(
        children: [
          if (!ready)
            const MapUnavailableView(reason: MapUnavailableReason.noKey)
          else ...[
            KakaoMap(
              option: KakaoMapOption(
                position: LatLng(start.lat, start.lng),
                zoomLevel: _zoom,
              ),
              onMapReady: (_) {},
              onMapError: _onMapError,
              onCameraMoveEnd: _onCameraMoveEnd,
            ),
            if (_mapError != null)
              MapUnavailableView(
                reason: MapUnavailableReason.authFailed,
                detail: _mapError,
              )
            else
              const IgnorePointer(child: Center(child: _CenterPin())),
          ],
        ],
      ),
      bottomNavigationBar: _ConfirmBar(
        address: _addressLine,
        onConfirm: canConfirm ? () => context.pop(_center) : null,
      ),
    );
  }
}

/// 가운데 고정 핀. 핀 끝이 정확히 가운데에 오도록 핀 높이만큼 올려 그린다.
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -_size / 2),
      child: const Icon(
        Icons.place_rounded,
        size: _size,
        color: AppColors.accent,
      ),
    );
  }
}

/// 핀 아래 주소와 "이 위치로 정하기".
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.address, required this.onConfirm});

  final String address;

  /// null이면 확정할 수 없는 상태다.
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '지도를 움직여 핀을 마지막으로 본 자리에 맞춰 주세요',
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle0,
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: RegisterLocationScreen.confirmKey,
                onPressed: onConfirm,
                child: const Text('이 위치로 정하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
