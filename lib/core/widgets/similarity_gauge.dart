import 'package:flutter/material.dart';

import '../../features/report/data/report.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 유사도 한 줄. 게이지 + 숫자 + 색 **3중 표기**(F-3.5.3).
///
/// 색 하나로만 구분하면 색각 이상 사용자가 읽지 못한다(비기능 요건 · 접근성).
/// 얼굴을 못 찾은 제보는 숫자 대신 "얼굴 미검출"로 적는다. 오류가 아니라
/// 정상 상태다(설계 결정 4번).
class SimilarityGauge extends StatelessWidget {
  const SimilarityGauge({
    required this.similarity,
    required this.grade,
    super.key,
  });

  /// 0~100. null이면 얼굴 미검출.
  final double? similarity;

  final SimilarityGrade grade;

  @override
  Widget build(BuildContext context) {
    final value = similarity;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: ColoredBox(
                color: AppColors.backgroundSubtle,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: ((value ?? 0) / 100).clamp(0, 1),
                  child: ColoredBox(color: _barColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          value == null ? '얼굴 미검출' : '${value.round()}%',
          style: AppTextStyles.badge.copyWith(color: _labelColor),
        ),
      ],
    );
  }

  Color get _barColor => switch (grade) {
    SimilarityGrade.high => AppColors.gradeHigh,
    SimilarityGrade.medium => AppColors.gradeMedium,
    SimilarityGrade.low => AppColors.gradeLow,
    SimilarityGrade.noFace => AppColors.gradeNoFace,
  };

  /// 숫자는 게이지보다 한 톤 가라앉힌다. 70% 미만까지 진한 파랑으로 적으면
  /// 확실한 제보와 애매한 제보가 같은 무게로 읽힌다.
  Color get _labelColor => switch (grade) {
    SimilarityGrade.high => AppColors.primary,
    SimilarityGrade.medium => AppColors.textSecondary,
    SimilarityGrade.low || SimilarityGrade.noFace => AppColors.textDisabled,
  };
}
