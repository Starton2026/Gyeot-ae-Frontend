import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// 하단 등록 소개 블록(F-1.6).
///
/// 위의 바로가기 띠와 같은 기능이지만 위계가 다르다. 위는 급한 보호자를 위한
/// 지름길이고, 여기는 평소 사용자가 이런 기능이 있다는 것을 알게 되는 자리다.
///
/// 112 안내를 함께 적는다. 곁애는 경찰 수색을 대신하지 않는다.
class GuardianRegisterBlock extends StatelessWidget {
  const GuardianRegisterBlock({this.onRegister, super.key});

  /// 실종자 등록(S7)으로 보낸다. 등록은 로그인이 필요하다.
  final VoidCallback? onRegister;

  static const Key registerButtonKey = Key('home_register_button');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '112 신고와 함께 등록하면, 주변 시민에게 바로 전달됩니다',
            style: AppTextStyles.body0.copyWith(
              color: AppColors.white.withValues(alpha: 0.82),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '사진 한 장으로 2분이면 됩니다',
            style: AppTextStyles.title0.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 13),
          FilledButton(
            key: registerButtonKey,
            onPressed: onRegister,
            style: AppTheme.cardButton(
              background: AppColors.white,
              foreground: AppColors.primary,
            ),
            child: const Text('실종자 등록하기'),
          ),
        ],
      ),
    );
  }
}
