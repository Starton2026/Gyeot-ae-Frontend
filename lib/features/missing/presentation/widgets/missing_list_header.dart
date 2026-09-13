import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/missing_case.dart';
import '../missing_list_providers.dart';

/// 건수 + 정렬 기준(F-2.3).
///
/// 건수는 지금 화면에 있는 개수가 아니라 조건에 맞는 전체 건수다. 스크롤을
/// 내리며 개수가 늘어나는 숫자는 "몇 건이 진행 중인가"를 말해주지 못한다.
///
/// **상태가 섞인 목록에서는 합계를 쓰지 않는다.** `전체 32건`은 32명이
/// 실종된 것으로 읽힌다. 그중 20건이 이미 찾은 사람이면 거짓말에 가깝다.
class MissingListHeader extends StatelessWidget {
  const MissingListHeader({
    required this.filter,
    required this.count,
    required this.sort,
    required this.onTapSort,
    this.activeCount,
    this.resolvedCount,
    super.key,
  });

  final MissingListFilter filter;
  final int count;

  /// [count]의 상태별 내역. 모르면 null이고, 그때는 합계만 적는다.
  final int? activeCount;
  final int? resolvedCount;

  final MissingSort sort;
  final VoidCallback onTapSort;

  static const Key sortButtonKey = Key('missing_sort_button');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CountLabel(
          filter: filter,
          count: count,
          activeCount: activeCount,
          resolvedCount: resolvedCount,
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

/// 왼쪽 건수. 상태가 섞였을 때만 둘로 쪼갠다.
class _CountLabel extends StatelessWidget {
  const _CountLabel({
    required this.filter,
    required this.count,
    required this.activeCount,
    required this.resolvedCount,
  });

  final MissingListFilter filter;
  final int count;
  final int? activeCount;
  final int? resolvedCount;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body1.copyWith(color: AppColors.textSecondary);

    final active = activeCount;
    final resolved = resolvedCount;
    // 한 상태만 있는 필터는 쪼갤 것이 없고, 발견 완료가 0건이면
    // "발견 0건"이 붙어봐야 읽는 사람만 늘어난다.
    final split =
        filter.status == CaseStatusFilter.all &&
        active != null &&
        resolved != null &&
        resolved > 0;

    if (!split) return Text('${filter.countLabel} $count건', style: style);

    // 아동·어르신도 상태가 섞이므로 함께 쪼갠다. 그때는 무엇을 세는지
    // 앞에 남겨야 "아동 진행 중 3건"으로 읽힌다.
    final scope = filter == MissingListFilter.all
        ? ''
        : '${filter.countLabel} ';

    return Text.rich(
      TextSpan(
        text: '$scope진행 중 $active건',
        style: style,
        children: [
          // 아래 카드가 흐려지는 것과 같은 톤으로 적는다. 같은 줄에 있어도
          // 급한 숫자와 끝난 숫자가 구분돼 보여야 한다.
          TextSpan(
            text: ' · 발견 $resolved건',
            style: style.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}
