import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'register_text_field.dart';

/// 키·몸무게(F-7.9). 선택 항목이다.
///
/// 접어 두지 않는다. 항목 이름 옆에 "선택"이 적혀 있어 필수 칸과 헷갈릴 일이
/// 없고, 접으면 누르기 전에는 이런 칸이 있는 줄도 모른다.
class RegisterBodyFields extends StatelessWidget {
  const RegisterBodyFields({
    required this.height,
    required this.weight,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.heightFieldKey,
    required this.weightFieldKey,
    super.key,
  });

  final String height;
  final String weight;
  final ValueChanged<String> onHeightChanged;
  final ValueChanged<String> onWeightChanged;
  final Key heightFieldKey;
  final Key weightFieldKey;

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '키·몸무게',
              style: AppTextStyles.subtitle0.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '선택',
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RegisterTextField(
                fieldKey: heightFieldKey,
                value: height,
                onChanged: onHeightChanged,
                hint: '키',
                suffixText: 'cm',
                keyboardType: TextInputType.number,
                inputFormatters: digits,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RegisterTextField(
                fieldKey: weightFieldKey,
                value: weight,
                onChanged: onWeightChanged,
                hint: '몸무게',
                suffixText: 'kg',
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
