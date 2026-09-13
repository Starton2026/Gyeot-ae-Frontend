import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 등록 폼 맨 위의 112 안내(F-7.1).
///
/// 보호자가 앱만 믿고 신고를 미루는 사고를 막는다. 곁애는 경찰 수색을
/// 대신하지 않고, 주변 시민에게 함께 알리는 역할이라는 것을 화면이 먼저 밝힌다.
class RegisterPoliceNotice extends StatelessWidget {
  const RegisterPoliceNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body0.copyWith(
      color: AppColors.textSecondary,
      height: 1.55,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundSubtle,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '112 신고를 먼저 해주세요. ',
                  style: style.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: '곁애는 경찰 수색을 대신하지 않고, 주변 시민에게 함께 알리는 역할을 합니다.',
                      style: style,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
