import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/kakao_login_button.dart';
import '../../../../core/widgets/mascot.dart';

/// 비로그인 MY 맨 위의 로그인 유도(F-8.1).
///
/// **무엇이 좋아지는지만 적는다.** 로그인하지 않으면 못 쓴다고 적으면, 제보는
/// 로그인 없이 된다는 이 서비스의 전제와 어긋나 보인다.
///
/// 버튼을 누르면 로그인 시트(S6)를 거치지 않고 바로 카카오로 간다. 이 카드가
/// 이미 로그인하면 무엇이 좋은지 말했으니, 같은 말을 하는 시트를 한 번 더
/// 띄우면 버튼을 두 번 누르게 된다.
class MyLoginCard extends StatelessWidget {
  const MyLoginCard({
    required this.onLogin,
    this.busy = false,
    this.errorText,
    super.key,
  });

  final VoidCallback onLogin;

  /// 카카오 로그인 창이 떠 있는 동안. 버튼이 눌리지 않는다.
  final bool busy;

  /// 로그인에 실패한 이유. 없으면 null이다.
  final String? errorText;

  static const Key loginButtonKey = Key('my_login');
  static const Key errorKey = Key('my_login_error');

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
              '로그인하면 더 편리하게 제보할 수 있어요',
              textAlign: TextAlign.center,
              style: AppTextStyles.title0,
            ),
            const SizedBox(height: 7),
            Text(
              '등록한 실종자를 관리하고,\n제보한 소식과 발견 소식을 빠르게 받아볼 수 있습니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            KakaoLoginButton(key: loginButtonKey, busy: busy, onPressed: onLogin),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                key: errorKey,
                textAlign: TextAlign.center,
                style: AppTextStyles.body0.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
