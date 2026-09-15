import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/media/photo_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dashed_box.dart';
import '../../../../core/widgets/form_field_label.dart';

/// 목격 사진 첨부(F-4.2). 이 화면에서 시민이 직접 채우는 유일한 칸이다.
///
/// 빈 자리 전체가 카메라 버튼이다. 목격자는 대개 그 사람을 눈앞에 두고
/// 꺼내는 화면이라, 촬영까지 한 번에 닿아야 한다. 앨범은 나중에 올리는 경우라
/// 아래 작은 글씨로 둔다.
class ReportPhotoField extends StatelessWidget {
  const ReportPhotoField({
    required this.photoPath,
    required this.onPick,
    super.key,
  });

  /// 고른 사진의 로컬 경로. null이면 빈 자리를 그린다.
  final String? photoPath;

  final void Function(PhotoSource source) onPick;

  static const Key cameraKey = Key('report_photo_camera');
  static const Key galleryKey = Key('report_photo_gallery');

  /// 사진 미리보기 높이. 시안 값이다.
  static const double _previewHeight = 186;

  /// 사진을 고르기 전 빈 자리. 미리보기보다 낮게 둬서, 아직 아무것도 없을 때
  /// 아래의 분석 칸이 한 화면에 더 들어오게 한다.
  static const double _emptyHeight = 140;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormFieldLabel('목격한 사진', required: true),
        const SizedBox(height: 8),
        if (path == null)
          _EmptySlot(onTap: () => onPick(PhotoSource.camera))
        else
          _Preview(path: path, onRetake: () => onPick(PhotoSource.camera)),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                '얼굴이 보이지 않아도 괜찮습니다.\n옷차림과 주변이 함께 찍히면 도움이 됩니다.',
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: galleryKey,
              onPressed: () => onPick(PhotoSource.gallery),
              child: const Text('앨범에서 선택'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 사진을 고르기 전. 상자 전체가 카메라 버튼이다.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ReportPhotoField._emptyHeight,
      child: DashedBox(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ReportPhotoField.cameraKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 30,
                  color: AppColors.primaryDisabled,
                ),
                const SizedBox(height: 10),
                Text(
                  '사진 찍기',
                  style: AppTextStyles.subtitle0.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '누르면 카메라가 열립니다',
                  style: AppTextStyles.body0.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 고른 사진. 오른쪽 아래에 다시 찍기를 얹는다.
class _Preview extends StatelessWidget {
  const _Preview({required this.path, required this.onRetake});

  final String path;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        height: ReportPhotoField._previewHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: AppColors.backgroundSubtle,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primaryDisabled,
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _RetakeChip(
                key: ReportPhotoField.cameraKey,
                onTap: onRetake,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetakeChip extends StatelessWidget {
  const _RetakeChip({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.textPrimary.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh_rounded, size: 14, color: AppColors.white),
              const SizedBox(width: 5),
              Text(
                '다시 찍기',
                style: AppTextStyles.badge.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
