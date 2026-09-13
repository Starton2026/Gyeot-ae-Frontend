import 'package:flutter/material.dart';

import '../../../../core/format/korean_particle.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 소프트 로그인(F-4.2.5·F-4.2.6).
///
/// **게스트 제보를 허용하면 생기는 공백을 메우는 유일한 자리다.** 제보는 이미
/// 끝났고 되돌릴 것이 없으니, 여기서 한 번 묻는 것은 부담이 아니다.
///
/// 강제하지 않는다. "괜찮습니다"를 눌러도 제보는 그대로 유효하다. 로그인을
/// 조건으로 걸면 목격자가 다음번에 제보 자체를 안 한다(설계 결정 1번).
class ReportDoneNotify extends StatelessWidget {
  const ReportDoneNotify({
    required this.name,
    required this.onLogin,
    required this.onSkip,
    super.key,
  });

  /// 실종자 이름. `하준이가 발견되면` 처럼 조사를 붙여 적는다.
  ///
  /// 아직 사건을 못 불러왔으면 null이다. 이름 없이도 묻는 말은 성립한다.
  final String? name;

  final VoidCallback onLogin;
  final VoidCallback onSkip;

  static const Key loginButtonKey = Key('report_done_login');
  static const Key skipButtonKey = Key('report_done_skip');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.backgroundSubtle,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name == null
                            ? '발견되면 알려드릴까요?'
                            : '${withSubjectParticle(name!)} 발견되면 알려드릴까요?',
                        style: AppTextStyles.subtitle0,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '결과를 알려드리고, 내 제보 이력도 남길 수 있습니다',
                        style: AppTextStyles.body0.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 11),
              FilledButton(
                key: loginButtonKey,
                onPressed: onLogin,
                child: const Text('로그인하고 알림 받기'),
              ),
              TextButton(
                key: skipButtonKey,
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('괜찮습니다'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
