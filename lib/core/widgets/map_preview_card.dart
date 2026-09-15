import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_icon.dart';

/// 지도 자리 카드. 홈의 주변 지도(F-1.3)와 상세의 이동 경로 미니 지도(F-3.4)가
/// 같은 모양을 쓴다.
///
/// 정적 카드다. 확대·이동·핀 탭이 없고 **카드 전체가 지도 탭으로 가는 버튼**이다.
/// 화면 안에서 지도를 조작하기 시작하면 그 화면이 지도 화면이 된다.
///
/// 지도는 [map]으로 받는다(보통 `StaticKakaoMap`). 없으면 회색 판이다.
class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({
    required this.height,
    required this.label,
    this.onTap,
    this.map,
    super.key,
  });

  /// 지도 자리의 높이. **고정이다.** 지도(플랫폼 뷰)는 크기가 바뀌는 중에
  /// 정리되면 엔진이 죽는다.
  final double height;

  /// 지도 자리에 그릴 것. 손가락을 먹지 않아야 카드 탭이 산다.
  final Widget? map;

  /// 푸터 왼쪽에 적는 말. "내 주변 실종 3건" · "제보 6건으로 복원한 이동 경로".
  final String label;

  /// null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: map ?? const ColoredBox(color: AppColors.neutralGray),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: AppTextStyles.subtitle0)),
                const SizedBox(width: 8),
                Text(
                  '지도에서 보기',
                  style: AppTextStyles.body1.copyWith(color: AppColors.primary),
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
