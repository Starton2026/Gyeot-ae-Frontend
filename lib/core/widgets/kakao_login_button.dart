import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_icon.dart';

/// "카카오로 시작하기" 버튼. 카카오가 정한 모양 그대로, 색과 비율을 바꾸지 않는다.
///
/// 로그인 시트(S6)와 MY 로그인 카드(S8)가 함께 쓴다. [busy]인 동안은 눌리지
/// 않고 돌아가는 표시를 그린다 — 카카오톡이 뜨기까지 틈이 있어, 그 사이 한 번
/// 더 누르면 로그인 창이 두 번 열린다.
class KakaoLoginButton extends StatelessWidget {
  const KakaoLoginButton({
    required this.onPressed,
    this.busy = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.kakaoYellow,
        foregroundColor: AppColors.kakaoLabel,
        disabledBackgroundColor: AppColors.kakaoYellow,
        disabledForegroundColor: AppColors.kakaoLabel,
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.kakaoLabel,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(AppIcons.kakao, size: 19),
                SizedBox(width: 8),
                Text('카카오로 시작하기'),
              ],
            ),
    );
  }
}
