import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 본문의 이름 줄.
///
/// 스크롤하면 상단바가 이 줄을 이어받는다(F-3.6). 그 시점을 계산하려고 화면이
/// 이 위젯의 위치를 재기 때문에, 화면에서 `key`를 넘겨 받는다.
class DetailNameLine extends StatelessWidget {
  const DetailNameLine({
    required this.name,
    required this.ageGenderLabel,
    super.key,
  });

  final String name;

  /// `7세 · 남아`.
  final String ageGenderLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            name,
            style: AppTextStyles.headline0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          ageGenderLabel,
          style: AppTextStyles.subtitle0.copyWith(
            color: AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
