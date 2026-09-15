import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 상세 화면 하단에 고정되는 제보 버튼(F-3.7).
///
/// 어디를 보고 있든 화면에 남는다. 목격자는 스크롤 중간에 "어? 이 옷" 하고
/// 알아채는데, 그때 버튼을 찾아 내려가야 한다면 이미 늦다.
///
/// 이 화면에서는 하단 네비게이션을 숨긴다. 버튼끼리 경쟁시키지 않는다.
class DetailReportCta extends StatelessWidget {
  const DetailReportCta({required this.label, this.onTap, super.key});

  /// "이 아이를 봤어요" · "이분을 봤어요".
  final String label;

  /// null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onTap;

  static const Key buttonKey = Key('detail_report_button');

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
              FilledButton(
                key: buttonKey,
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.accent,
                  disabledForegroundColor: AppColors.white,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 8),
              Text(
                '사진 한 장이면 됩니다 · 로그인 없이 제보',
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
