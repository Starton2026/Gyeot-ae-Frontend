import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mascot.dart';

/// 받은 알림이 없을 때.
///
/// 빈 상태라 이음이가 나와도 되는 자리다(설계 결정 8번). 무엇이 여기에
/// 모이는지만 알려준다.
class NotificationEmptyView extends StatelessWidget {
  const NotificationEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(MascotPose.find, height: 96),
          const SizedBox(height: 16),
          const Text(
            '아직 받은 알림이 없어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.title0,
          ),
          const SizedBox(height: 6),
          Text(
            '주변 실종 신고, 내 사건 제보,\n내가 제보한 사람의 발견 소식이 여기에 모여요',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
