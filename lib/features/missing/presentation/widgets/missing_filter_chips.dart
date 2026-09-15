import 'package:flutter/material.dart';

import '../../../../core/widgets/app_choice_chip.dart';
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
            AppChoiceChip(
              label: filter.chipLabel,
              selected: filter == selected,
              onTap: () => onSelect(filter),
            ),
          ],
        ],
      ),
    );
  }
}
