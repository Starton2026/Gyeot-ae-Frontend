import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../missing_list_providers.dart';

/// 목록 필터 칩 한 줄(F-2.2). 하나만 고를 수 있다.
class MissingFilterChips extends StatelessWidget {
  const MissingFilterChips({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final MissingListFilter selected;
  final ValueChanged<MissingListFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in MissingListFilter.values) ...[
            if (filter != MissingListFilter.values.first)
              const SizedBox(width: 7),
            _Chip(
              filter: filter,
              selected: filter == selected,
              onTap: () => onSelect(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final MissingListFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(filter.chipLabel),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      labelStyle: AppTextStyles.body1.copyWith(
        color: selected ? AppColors.white : AppColors.textSecondary,
      ),
    );
  }
}
