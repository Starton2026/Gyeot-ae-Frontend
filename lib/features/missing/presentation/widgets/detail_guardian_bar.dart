import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 보호자에게만 보이는 하단 메뉴(F-3.8). 제보 버튼 자리를 대신한다.
///
/// 내 아이 사건에서 "이 아이를 봤어요"는 보호자가 누를 버튼이 아니다. 대신
/// 보호자가 이 화면에서 할 일 — 정보 고치기, 사진 더하기, 찾았다고 알리기 —
/// 을 둔다.
///
/// 발견 완료만 채운 버튼이다. 이 서비스에서 가장 좋은 소식이고, 찾았을 때
/// 보호자가 가장 먼저 찾을 버튼이다. 누르면 한 번 묻는다.
class DetailGuardianBar extends StatelessWidget {
  const DetailGuardianBar({
    required this.onEdit,
    required this.onAddPhotos,
    required this.onResolve,
    this.busy = false,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onAddPhotos;
  final VoidCallback onResolve;

  /// 사진을 올리거나 발견 완료를 보내는 중. 버튼을 잠근다.
  final bool busy;

  static const Key editKey = Key('detail_guardian_edit');
  static const Key addPhotosKey = Key('detail_guardian_add_photos');
  static const Key resolveKey = Key('detail_guardian_resolve');

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
                  Expanded(
                    child: OutlinedButton(
                      key: editKey,
                      onPressed: busy ? null : onEdit,
                      child: const Text('정보 수정'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: addPhotosKey,
                      onPressed: busy ? null : onAddPhotos,
                      child: const Text('사진 추가'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: resolveKey,
                onPressed: busy ? null : onResolve,
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('찾았어요 · 발견 완료'),
              ),
              const SizedBox(height: 8),
              Text(
                '내가 등록한 사건이에요 · 보호자에게만 보이는 메뉴',
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
