import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 발견 완료된 사건의 하단. 제보 버튼 자리에 놓인다.
///
/// **찾은 사람에게는 제보를 받지 않는다.** 버튼을 남기면 "봤어요" 알림이 보호자에게
/// 가고, 경로 끝에 발견 뒤의 점이 붙는다. 사건은 목록에 그대로 남지만(설계 결정
/// 7번) 이제 할 일은 없다는 것만 조용히 알린다.
class DetailResolvedNote extends StatelessWidget {
  const DetailResolvedNote({super.key});

  static const Key noteKey = Key('detail_resolved_note');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: noteKey,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSubtle,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('찾았어요', style: AppTextStyles.title0),
              const SizedBox(height: 4),
              Text(
                '함께 봐 주셔서 고맙습니다. 더는 제보를 받지 않아요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
