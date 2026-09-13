import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../data/missing_case.dart';
import 'register_error_text.dart';

/// 구분 칩(F-7.5). 아동 · 어르신 · 그 외 중 하나.
///
/// **진단명으로 나누지 않는다.** 배회는 진단과 상관없이 일어나고, 등록하는
/// 순간에 진단 여부를 따지게 하면 손이 멈춘다. 긴급도의 취약도 가중치가 이
/// 값으로 붙는다.
class RegisterCategoryChips extends StatelessWidget {
  const RegisterCategoryChips({
    required this.selected,
    required this.onSelect,
    this.errorText,
    super.key,
  });

  final MissingCategory? selected;
  final ValueChanged<MissingCategory> onSelect;
  final String? errorText;

  static String _label(MissingCategory category) => switch (category) {
    MissingCategory.child => '아동',
    MissingCategory.elderly => '어르신',
    MissingCategory.other => '그 외',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FormFieldLabel('구분', required: true),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          children: [
            for (final category in MissingCategory.values)
              ChoiceChip(
                label: Text(_label(category)),
                selected: category == selected,
                showCheckmark: false,
                onSelected: (_) => onSelect(category),
                backgroundColor: AppColors.background,
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: category == selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
                labelStyle: AppTextStyles.body1.copyWith(
                  color: category == selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        RegisterErrorText(errorText),
      ],
    );
  }
}
