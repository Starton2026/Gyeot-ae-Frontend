import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'register_text_field.dart';

/// 키·몸무게(F-7.9). **선택 항목이라 접어 둔다.**
///
/// 등록은 2분 안에 끝나야 한다. 펼쳐 두면 필수 칸과 같은 무게로 읽혀 손이
/// 멈춘다. 이미 적은 값이 있으면(임시저장에서 왔으면) 펼친 채로 시작한다.
class RegisterBodyFields extends StatefulWidget {
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

  static const Key toggleKey = Key('register_body_toggle');

  @override
  State<RegisterBodyFields> createState() => _RegisterBodyFieldsState();
}

class _RegisterBodyFieldsState extends State<RegisterBodyFields> {
  late bool _open = widget.height.isNotEmpty || widget.weight.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: RegisterBodyFields.toggleKey,
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
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
                const Spacer(),
                Icon(
                  _open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: RegisterTextField(
                  fieldKey: widget.heightFieldKey,
                  value: widget.height,
                  onChanged: widget.onHeightChanged,
                  hint: '키',
                  suffixText: 'cm',
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RegisterTextField(
                  fieldKey: widget.weightFieldKey,
                  value: widget.weight,
                  onChanged: widget.onWeightChanged,
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
      ],
    );
  }
}
