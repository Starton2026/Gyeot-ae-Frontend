import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

/// 지도 프리뷰 카드(F-1.3).
///
/// 정적 카드다. 확대·이동·핀 탭이 전부 없고 **카드 전체가 지도 탭으로 가는
/// 버튼**이다. 홈에서 지도를 조작하기 시작하면 홈이 지도 화면이 된다.
///
/// TODO(지도): KAKAO_MAP_KEY가 준비되면 [_MapPlaceholder] 자리에 실종 위치 핀만
/// 찍은 카카오맵을 넣는다. 지금은 회색 판으로 자리만 잡아둔다.
class NearbyMapPreview extends StatelessWidget {
  const NearbyMapPreview({required this.nearbyCount, this.onTap, super.key});

  /// 내 주변에서 진행 중인 사건 수.
  final int nearbyCount;

  /// null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onTap;

  /// 지도 자리의 높이(F-1.3).
  static const double mapHeight = 150;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const _MapPlaceholder(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '내 주변 실종 $nearbyCount건',
                    style: AppTextStyles.subtitle0,
                  ),
                ),
                Text(
                  '지도에서 보기',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 3),
                const AppIcon(
                  AppIcons.rightAngleBracket,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(onTap: onTap, child: card);
  }
}

/// 지도가 들어올 자리.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: NearbyMapPreview.mapHeight,
      width: double.infinity,
      child: ColoredBox(color: AppColors.neutralGray),
    );
  }
}
