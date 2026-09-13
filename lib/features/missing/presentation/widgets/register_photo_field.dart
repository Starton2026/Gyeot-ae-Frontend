import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/dashed_box.dart';
import '../../../../core/widgets/form_field_label.dart';
import 'register_error_text.dart';

/// 실종자 사진(F-7.2). 여러 장, 첫 장이 대표.
///
/// 여러 장일수록 AI 대조가 정확해진다. 서버가 장마다 얼굴 벡터를 뽑아 두고
/// 제보가 오면 가장 닮은 장의 점수를 쓴다.
///
/// 추가 칸을 누르면 **바로 앨범이 열린다.** 제보창과 달리 카메라를 묻지
/// 않는다 — 실종된 사람은 눈앞에 없어서 찍을 수가 없다.
class RegisterPhotoField extends StatelessWidget {
  const RegisterPhotoField({
    required this.photoPaths,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
    this.errorText,
    super.key,
  });

  final List<String> photoPaths;

  /// 더 올릴 수 있는가. 다 찼으면 추가 칸을 숨긴다.
  final bool canAdd;

  /// 앨범을 연다.
  final VoidCallback onAdd;

  final ValueChanged<int> onRemove;
  final String? errorText;

  static const Key addKey = Key('register_photo_add');

  /// n번째 사진의 빼기 버튼.
  static Key removeKey(int index) => ValueKey('register_photo_remove_$index');

  /// 한 줄에 보이는 칸 수. 넘치면 옆으로 민다.
  static const int _visibleSlots = 3;
  static const double _gap = 9;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormFieldLabel('사진', required: true),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                (constraints.maxWidth - _gap * (_visibleSlots - 1)) /
                _visibleSlots;
            final height = width * 4 / 3;

            return SizedBox(
              height: height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoPaths.length + (canAdd ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(width: _gap),
                itemBuilder: (context, index) => SizedBox(
                  width: width,
                  child: index < photoPaths.length
                      ? _PhotoSlot(
                          path: photoPaths[index],
                          isMain: index == 0,
                          removeKey: removeKey(index),
                          onRemove: () => onRemove(index),
                        )
                      : _AddSlot(onTap: onAdd),
                ),
              ),
            );
          },
        ),
        if (errorText != null)
          RegisterErrorText(errorText)
        else ...[
          const SizedBox(height: 7),
          Text(
            '여러 장 올릴수록 AI 대조 정확도가 올라갑니다. 최근 사진, 전신 사진이 특히 도움이 됩니다.',
            style: AppTextStyles.body0.copyWith(
              color: AppColors.textDisabled,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// 올린 사진 한 장. 첫 장에는 "대표"를 붙인다.
class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.path,
    required this.isMain,
    required this.removeKey,
    required this.onRemove,
  });

  final String path;
  final bool isMain;
  final Key removeKey;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
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
          if (isMain)
            Positioned(
              left: 6,
              top: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    '대표',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: IconButton(
              key: removeKey,
              onPressed: onRemove,
              tooltip: '사진 빼기',
              icon: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.62),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 사진을 더 올리는 점선 칸. 누르면 앨범이 열린다.
class _AddSlot extends StatelessWidget {
  const _AddSlot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedBox(
      radius: 13,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: RegisterPhotoField.addKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: const Center(
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 24,
              color: AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
