import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 게스트 이력이 어디에 있는지 알려준다(F-8.2).
///
/// **로그인을 강요가 아니라 정보로 전한다.** "앱을 지우면 사라진다"는 사실을
/// 먼저 적고, 그래서 로그인하면 어떻게 되는지를 뒤에 붙인다. 순서를 바꾸면
/// 겁을 주는 문장이 된다.
class MyDeviceNote extends StatelessWidget {
  const MyDeviceNote({super.key});

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
                '이 기기에만 저장된 기록입니다. 앱을 지우면 사라집니다. '
                '로그인하면 계정으로 옮겨 보관됩니다.',
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
