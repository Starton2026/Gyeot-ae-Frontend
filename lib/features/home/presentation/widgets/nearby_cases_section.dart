import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_case_tile.dart';
import '../../../missing/data/missing_case.dart';

/// "내 주변" 섹션(F-1.4). 긴급도순으로 고정된 몇 건과 전체 보기 버튼.
///
/// 정렬은 긴급도 알고리즘이 정한다(기능정의서 5.1). 사용자가 순서를 올릴 수
/// 있는 조작은 두지 않는다(설계 결정 6번).
class NearbyCasesSection extends StatelessWidget {
  const NearbyCasesSection({
    required this.cases,
    required this.areaName,
    required this.totalCount,
    this.onTapCase,
    this.onTapMore,
    super.key,
  });

  final List<MissingCaseSummary> cases;

  /// "인천 남동구 기준 · 긴급도순"의 앞부분. **지명을 모르면 null이다.**
  ///
  /// 왼쪽에 이미 "내 주변"이 있어서, 지명을 모를 때 "현재 위치 기준"을 덧붙이면
  /// 같은 말을 두 번 하는 셈이 된다.
  final String? areaName;

  /// 진행 중인 사건 전체 수. 전체 보기 버튼 문구에 쓴다.
  final int totalCount;

  /// null이면 누를 수 없는 상태로 그린다.
  final void Function(MissingCaseSummary summary)? onTapCase;
  final VoidCallback? onTapMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('내 주변', style: AppTextStyles.title0),
            const Spacer(),
            Text(
              areaName == null ? '긴급도순' : '$areaName 기준 · 긴급도순',
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (cases.isEmpty)
          const _EmptyNearby()
        else
          for (final (index, summary) in cases.indexed) ...[
            if (index > 0) const Divider(height: 1),
            MissingCaseTile(
              summary: summary,
              onTap: onTapCase == null ? null : () => onTapCase!(summary),
            ),
          ],
        if (totalCount > cases.length) ...[
          const SizedBox(height: 6),
          _MoreButton(totalCount: totalCount, onTap: onTapMore),
        ],
      ],
    );
  }
}

/// 주변에 사건이 없는 날. 드물지만 정상 상태다.
class _EmptyNearby extends StatelessWidget {
  const _EmptyNearby();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Text(
        '주변에 진행 중인 사건이 없어요',
        textAlign: TextAlign.center,
        style: AppTextStyles.subtitle1.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// "진행 중인 사건 14건 모두 보기". 실종자 목록(S2)으로 간다.
class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.totalCount, this.onTap});

  final int totalCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSubtle,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Text(
            '진행 중인 사건 $totalCount건 모두 보기',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
