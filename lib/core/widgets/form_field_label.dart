import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 폼의 항목 이름. `목격한 사진 *`.
///
/// 제보창(S4)과 등록 폼(S7)이 함께 쓴다. 별표는 관심색으로 적는다. 별표가
/// 붙은 자리를 세는 것만으로 무엇이 남았는지 알 수 있어야 한다.
class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.text, {this.required = false, super.key});

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
