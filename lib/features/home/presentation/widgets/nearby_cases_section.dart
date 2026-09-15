import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_case_tile.dart';
import '../../../missing/data/missing_case.dart';

/// "내 주변" 섹션(F-1.4). 긴급도순으로 고정된 몇 건.
///
/// 정렬은 긴급도 알고리즘이 정한다(기능정의서 5.1). 사용자가 순서를 올릴 수
/// 있는 조작은 두지 않는다(설계 결정 6번).
///
/// 목록 아래에 "전체 보기" 버튼을 두지 않는다. 하단 실종자 탭과 같은 곳으로
/// 가는 길이 두 개였고, "내 주변" 아래에서 전체 건수를 말하니 주변 건수로
/// 읽혔다.
class NearbyCasesSection extends StatelessWidget {
  const NearbyCasesSection({
    required this.cases,
    required this.areaName,
    this.onTapCase,
    super.key,
  });

  final List<MissingCaseSummary> cases;

  /// "인천 남동구 기준 · 긴급도순"의 앞부분. **지명을 모르면 null이다.**
  ///
  /// 왼쪽에 이미 "내 주변"이 있어서, 지명을 모를 때 "현재 위치 기준"을 덧붙이면
  /// 같은 말을 두 번 하는 셈이 된다.
  final String? areaName;

  /// null이면 누를 수 없는 상태로 그린다.
  final void Function(MissingCaseSummary summary)? onTapCase;

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
        style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
