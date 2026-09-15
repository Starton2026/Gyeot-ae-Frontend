import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 화면 아래에 고정되는 취소·제보(F-4.6).
///
/// **분석을 마치기 전에는 제보 버튼을 숨기지 않고 회색으로 둔다.** 버튼이
/// 사라지면 무엇을 더 해야 끝나는지 알 수 없다. 회색으로 남겨두면 아래
/// 안내문과 묶여서 "분석하면 눌린다"가 읽힌다.
class ReportSubmitBar extends StatelessWidget {
  const ReportSubmitBar({
    required this.canSubmit,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
    super.key,
  });

  final bool canSubmit;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  static const Key cancelButtonKey = Key('report_cancel_button');
  static const Key submitButtonKey = Key('report_submit_button');

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
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: FilledButton(
                      key: cancelButtonKey,
                      onPressed: submitting ? null : onCancel,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.backgroundSubtle,
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: submitButtonKey,
                      onPressed: canSubmit ? onSubmit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.white,
                        // 기본 비활성색은 옅은 파랑이라, 관심색 버튼이
                        // 꺼졌을 때 파란 버튼이 하나 더 있는 것처럼 보인다.
                        disabledBackgroundColor: AppColors.brandReliability,
                        disabledForegroundColor: AppColors.textSecondary,
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text('제보'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                canSubmit
                    ? '보호자에게 바로 전달됩니다 · 로그인 없이 제보'
                    : '분석을 마치면 제보할 수 있습니다',
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
