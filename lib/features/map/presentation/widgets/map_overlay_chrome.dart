import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 지도 위에 얹는 작은 조각들. 내 위치 버튼과 건수 안내를 함께 둔다.
///
/// 둘 다 지도 오른쪽 아래·왼쪽 아래에 붙어 카드 캐러셀 바로 위에 놓이는
/// 한 덩어리라, 화면에서 자리를 따로 잡지 않도록 묶었다.
class MapOverlayChrome extends StatelessWidget {
  const MapOverlayChrome({
    required this.hint,
    required this.onMyLocation,
    super.key,
  });

  /// "이 지역 진행 중 5건 · 긴급도순".
  final String hint;

  final VoidCallback onMyLocation;

  static const Key myLocationButtonKey = Key('map_my_location_button');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _RoundButton(
            key: myLocationButtonKey,
            onTap: onMyLocation,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            child: Text(
              hint,
              style: AppTextStyles.badge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 내 위치로 카메라를 되돌리는 버튼(F-5.1.6).
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '내 위치로',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.24),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: AppColors.background,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                Icons.my_location_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
