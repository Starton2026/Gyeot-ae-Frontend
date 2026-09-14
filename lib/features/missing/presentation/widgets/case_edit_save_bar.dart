import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 정보 수정 화면 하단의 저장 버튼.
class CaseEditSaveBar extends StatelessWidget {
  const CaseEditSaveBar({
    required this.saving,
    required this.onSave,
    required this.buttonKey,
    super.key,
  });

  final bool saving;
  final VoidCallback onSave;
  final Key buttonKey;

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
          child: FilledButton(
            key: buttonKey,
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('저장하기'),
          ),
        ),
      ),
    );
  }
}
