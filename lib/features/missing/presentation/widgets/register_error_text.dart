import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 등록 폼의 칸 아래에 붙는 빨간 안내. 글자 입력칸이 아닌 칸(사진·성별·구분·
/// 위치)이 쓴다. 입력칸은 `InputDecoration.errorText`가 같은 자리를 그린다.
///
/// [message]가 null이면 아무것도 그리지 않는다.
class RegisterErrorText extends StatelessWidget {
  const RegisterErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: AppTextStyles.body0.copyWith(color: AppColors.error),
      ),
    );
  }
}
