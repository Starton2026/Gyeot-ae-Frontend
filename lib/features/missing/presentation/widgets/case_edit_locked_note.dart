import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 정보 수정에서 바꿀 수 없는 칸을 먼저 알린다.
///
/// 칸이 아예 없으면 보호자는 "이름 오타는 어디서 고치지?" 하고 화면을 뒤진다.
/// 없는 이유까지 적는다 — 경과 시간과 긴급도가 달라지면 목록 순서를 조작할 수
/// 있다(설계 결정 6번).
class CaseEditLockedNote extends StatelessWidget {
  const CaseEditLockedNote({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.lock_outline,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                // 줄마다 폭 안에 들어가게 끊었다. 이어 쓰면 한글이 단어 중간에서
                // 넘어간다.
                '이름·나이·성별·구분·실종 일시는 바꿀 수 없어요.\n'
                '바꾸면 경과 시간과 긴급도가 달라지기 때문이에요.',
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
