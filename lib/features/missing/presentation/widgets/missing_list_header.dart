import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/missing_case.dart';
import '../missing_list_providers.dart';

/// 건수 + 정렬 기준(F-2.3).
///
/// 건수는 지금 화면에 있는 개수가 아니라 조건에 맞는 전체 건수다. 스크롤을
/// 내리며 개수가 늘어나는 숫자는 "몇 건이 진행 중인가"를 말해주지 못한다.
class MissingListHeader extends StatelessWidget {
  const MissingListHeader({
    required this.filter,
    required this.count,
    required this.sort,
    required this.onTapSort,
    super.key,
  });

  final MissingListFilter filter;
  final int count;
  final MissingSort sort;
  final VoidCallback onTapSort;

  static const Key sortButtonKey = Key('missing_sort_button');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${filter.countLabel} $count건',
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        InkWell(
          key: sortButtonKey,
          onTap: onTapSort,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sort.label,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
