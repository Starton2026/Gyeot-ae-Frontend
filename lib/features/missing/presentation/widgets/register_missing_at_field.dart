import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form_field_label.dart';

/// 실종 일시(F-7.8). 날짜와 시각을 따로 누른다.
///
/// 이 값에서 경과 시간과 골든타임이 계산된다. 등록한 뒤에는 고칠 수 없다
/// (명세서 8 — 경과 시간 조작 방지).
class RegisterMissingAtField extends StatelessWidget {
  const RegisterMissingAtField({
    required this.missingAt,
    required this.onPickDate,
    required this.onPickTime,
    super.key,
  });

  final DateTime missingAt;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  static const Key dateKey = Key('register_missing_date');
  static const Key timeKey = Key('register_missing_time');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormFieldLabel('실종 일시', required: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PickerBox(
                key: dateKey,
                text: koreanDateLabel(missingAt, relative: false),
                onTap: onPickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerBox(
                key: timeKey,
                text: koreanClockLabel(missingAt),
                onTap: onPickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 입력칸처럼 생긴 누르는 상자. 끝에 아래 꺾쇠.
class _PickerBox extends StatelessWidget {
  const _PickerBox({required this.text, required this.onTap, super.key});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSubtle,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 15, 12, 15),
          child: Row(
            children: [
              Expanded(child: Text(text, style: AppTextStyles.subtitle1)),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
