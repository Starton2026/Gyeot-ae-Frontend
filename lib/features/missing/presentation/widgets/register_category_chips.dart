import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../data/missing_case.dart';
import 'register_error_text.dart';

/// 구분 칩(F-7.5). 아동 · 성인 · 어르신 중 하나.
///
/// **진단명으로 나누지 않는다.** 배회는 진단과 상관없이 일어나고, 등록하는
/// 순간에 진단 여부를 따지게 하면 손이 멈춘다. 긴급도의 취약도 가중치가 이
/// 값으로 붙는다.
///
/// 나이를 적으면 알아서 골라진다. 구분이 나이대라서 서버 값 `other`는 '그 외'가
/// 아니라 18~64세, 곧 성인이다. 나이 순서대로 아동 · 성인 · 어르신으로 늘어놓는다.
class RegisterCategoryChips extends StatelessWidget {
  const RegisterCategoryChips({
    required this.selected,
    required this.onSelect,
    this.autoPicked = false,
    this.errorText,
    super.key,
  });

  final MissingCategory? selected;
  final ValueChanged<MissingCategory> onSelect;

  /// 나이로 골라 둔 것이다. 바꿀 수 있다고 한 줄 알린다.
  final bool autoPicked;

  final String? errorText;

  static const Key autoNoteKey = Key('register_category_auto_note');

  static const List<MissingCategory> _order = [
    MissingCategory.child,
    MissingCategory.other,
    MissingCategory.elderly,
  ];

  static String _label(MissingCategory category) => switch (category) {
    MissingCategory.child => '아동',
    MissingCategory.elderly => '어르신',
    MissingCategory.other => '성인',
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
            for (final category in _order)
              AppChoiceChip(
                label: _label(category),
                selected: category == selected,
                onTap: () => onSelect(category),
              ),
          ],
        ),
        if (autoPicked && errorText == null)
          Padding(
            key: autoNoteKey,
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '나이에 맞춰 골라 두었어요. 다르면 바꿔 주세요.',
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        RegisterErrorText(errorText),
      ],
    );
  }
}
