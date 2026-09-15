import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 고르는 칩 하나. 고른 칩은 브랜드 파랑으로 채우고 글자를 희게 뒤집는다.
///
/// 목록 필터(S2)·등록 구분(S7)·알림 설정(S8)이 같은 모양을 쓴다. 칩마다 색을
/// 따로 정하면 화면을 옮길 때 "골랐다"의 모양이 달라진다.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      labelStyle: AppTextStyles.body1.copyWith(
        color: selected ? AppColors.white : AppColors.textSecondary,
      ),
    );
  }
}
