import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mascot.dart';

/// 조건에 맞는 사건이 없을 때.
///
/// 검색 결과 없음은 실패가 아니라 안내의 자리라서, 이음이가 나와도 되는 몇 안
/// 되는 화면이다(설계 결정 8번).
class MissingEmptyView extends StatelessWidget {
  const MissingEmptyView({required this.keyword, super.key});

  /// 검색 중이면 그 말. 필터만 걸린 상태면 빈 문자열.
  final String keyword;

  @override
  Widget build(BuildContext context) {
    final searching = keyword.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(MascotPose.find, height: 96),
          const SizedBox(height: 16),
          Text(
            searching ? '"$keyword" 결과가 없어요' : '해당하는 사건이 없어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.title0,
          ),
          const SizedBox(height: 6),
          Text(
            searching ? '이름이나 지역을 다시 확인해 주세요' : '다른 조건으로 찾아보세요',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
