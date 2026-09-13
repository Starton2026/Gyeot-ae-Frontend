import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 화면 아래에 고정되는 등록하기.
///
/// **빈 칸이 있어도 버튼을 끄지 않는다.** 손이 떨리는 상황에서 회색 버튼만
/// 남으면 무엇이 빠졌는지 알 수 없다. 누르면 빠진 칸으로 데려간다.
class RegisterSubmitBar extends StatelessWidget {
  const RegisterSubmitBar({
    required this.submitting,
    required this.onSubmit,
    super.key,
  });

  final bool submitting;
  final VoidCallback onSubmit;

  static const Key submitButtonKey = Key('register_submit_button');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: submitButtonKey,
                // 보내는 중에는 막는다. 두 번 누르면 같은 사람이 두 건 올라간다.
                onPressed: submitting ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('등록하기'),
              ),
              const SizedBox(height: 8),
              Text(
                '등록 즉시 반경 5km 이내 사용자에게 알림이 갑니다',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
