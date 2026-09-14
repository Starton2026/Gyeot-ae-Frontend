import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 이 설정이 막지 않는 알림을 알려준다.
///
/// 보호자가 반경을 줄이거나 야간 알림을 끄면서 **내 아이 제보까지 끊기는 줄
/// 알면 안 된다.** 서버는 제보 도착·발견 완료 알림에 이 설정을 보지 않는다.
class NotificationAlwaysNote extends StatelessWidget {
  const NotificationAlwaysNote({super.key});

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
                Icons.info_outline,
                size: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                // 줄마다 폭 안에 들어가게 끊었다. 이어 쓰면 한글이 단어 중간에서
                // 넘어간다.
                '위 설정은 주변 실종 신고 알림에만 적용돼요.\n'
                '내가 등록한 실종자의 제보 알림과\n'
                '내가 제보한 사건의 발견 소식은 항상 받아요.',
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
