import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// MY의 구역 제목. 왼쪽에 무엇인지, 오른쪽에 몇 건인지.
///
/// 건수를 제목 옆에 붙이는 이유는, 목록을 다 내려보지 않아도 내가 얼마나
/// 보탰는지 한눈에 들어와야 하기 때문이다.
class MySectionHeader extends StatelessWidget {
  const MySectionHeader({required this.title, this.trailing, super.key});

  final String title;

  /// `2건`처럼 오른쪽에 붙는 말. 없으면 제목만 그린다.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final count = trailing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.title0)),
          if (count != null)
            Text(
              count,
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
