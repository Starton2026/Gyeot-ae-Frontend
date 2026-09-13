import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 목록에서 진행 중이 끝나고 발견 완료가 시작되는 자리.
///
/// **발견 완료를 목록에서 지우지 않기 때문에**(설계 결정 7번) 스크롤을 내리면
/// 어느 순간 카드가 흐려진다. 이유를 안 적으면 앱이 고장 난 것처럼 보인다.
///
/// 동시에 이 줄은 성과 표시다. 아래로 쌓인 건수가 곧 "이 서비스로 찾았다"는
/// 증거라, 건수를 숨기지 않고 줄 한가운데 적는다.
class MissingResolvedDivider extends StatelessWidget {
  const MissingResolvedDivider({required this.count, super.key});

  /// 이 아래로 이어지는 발견 완료 건수. **지금 화면에 그려진 개수가 아니라
  /// 조건에 맞는 전체 건수다.**
  final int count;

  static const Key dividerKey = Key('missing_resolved_divider');

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: dividerKey,
      // 목록이 이미 좌우 여백을 갖고 있다. 여기서 또 주면 선이 안쪽으로
      // 들어가 항목 사이 구분선과 어긋난다.
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '여기부터 발견된 사건 $count건',
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }
}
