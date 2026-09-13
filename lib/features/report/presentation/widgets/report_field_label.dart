import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 제보창의 항목 이름. `목격한 사진 *`.
///
/// 별표는 관심색으로 적는다. 이 화면에서 필수는 사진과 분석 둘뿐이라,
/// 별표가 붙은 자리를 세는 것만으로 무엇이 남았는지 알 수 있어야 한다.
class ReportFieldLabel extends StatelessWidget {
  const ReportFieldLabel(this.text, {this.required = false, super.key});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: required
            ? const [
                TextSpan(text: ' *', style: TextStyle(color: AppColors.accent)),
              ]
            : null,
      ),
      style: AppTextStyles.subtitle0.copyWith(color: AppColors.textSecondary),
    );
  }
}
