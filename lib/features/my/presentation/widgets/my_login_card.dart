import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/mascot.dart';

/// 비로그인 MY 맨 위의 로그인 유도(F-8.1).
///
/// **무엇이 좋아지는지만 적는다.** 로그인하지 않으면 못 쓴다고 적으면, 제보는
/// 로그인 없이 된다는 이 서비스의 전제와 어긋나 보인다.
class MyLoginCard extends StatelessWidget {
  const MyLoginCard({required this.onLogin, super.key});

  final VoidCallback onLogin;

  static const Key loginButtonKey = Key('my_login');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // 시안의 옅은 파랑→분홍. 브랜드 5색 안에서 가장 가까운 두 톤이다.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.backgroundSubtle, AppColors.brandHope],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Mascot(MascotPose.basic, height: 96)),
            const SizedBox(height: 8),
            const Text(
              '로그인하면 더 챙겨드려요',
              textAlign: TextAlign.center,
              style: AppTextStyles.title0,
            ),
            const SizedBox(height: 7),
            Text(
              '등록한 사건을 관리하고,\n제보한 사람이 발견 소식을 받을 수 있습니다',
              textAlign: TextAlign.center,
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: loginButtonKey,
              onPressed: onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kakaoYellow,
                foregroundColor: AppColors.kakaoLabel,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(AppIcons.kakao, size: 18),
                  SizedBox(width: 8),
                  Text('카카오로 시작하기'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
