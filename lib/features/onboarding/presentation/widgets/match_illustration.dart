import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/similarity_arc_gauge.dart';
import '../../../report/data/report.dart';

/// 온보딩 2장의 그림. 등록 사진과 제보 사진을 대조해 유사도를 내는 장면.
///
/// **S4-1에서 쓰는 게이지를 그대로 쓴다.** 온보딩에서 본 것을 제보할 때 다시
/// 만나야 "아까 그거"로 읽힌다. 그림을 따로 그리면 같은 것이 두 모양이 된다.
class MatchIllustration extends StatelessWidget {
  const MatchIllustration({super.key});

  /// 시안에 적힌 값. 애매한 구간이라야 이 장의 말("확신이 없어도 괜찮습니다")이
  /// 성립한다. 90%대를 보여주면 확신이 있을 때만 제보하라는 말로 읽힌다.
  static const double _sample = 63;

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SimilarityArcGauge(
          similarity: _sample,
          grade: SimilarityGrade.medium,
        ),
        SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PhotoChip(label: '등록'),
            SizedBox(width: 10),
            _PhotoChip(label: '제보'),
          ],
        ),
      ],
    );
  }
}

class _PhotoChip extends StatelessWidget {
  const _PhotoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_rounded,
            size: 22,
            color: AppColors.primaryDisabled,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
