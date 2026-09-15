import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 등록 사진 ↔ 제보 사진을 나란히 둔다(F-4.1.3).
///
/// 숫자만으로는 납득되지 않는다. 63%가 맞는지 틀린지는 결국 사람 눈이
/// 판단하고, 두 장을 나란히 놓는 것이 그 판단을 돕는 유일한 방법이다.
///
/// 왼쪽은 서버가 준 경로, 오른쪽은 방금 고른 로컬 파일이라 불러오는 길이
/// 다르다. 두 칸이 같아 보이도록 상자는 한 군데서 그린다.
class AnalysisCompareRow extends StatelessWidget {
  const AnalysisCompareRow({
    required this.registeredPhoto,
    required this.capturedPath,
    super.key,
  });

  /// 최고 유사도를 낸 등록 사진. 없으면 대표 사진을 넘긴다.
  final String? registeredPhoto;

  /// 방금 고른 사진의 로컬 경로.
  final String? capturedPath;

  @override
  Widget build(BuildContext context) {
    final registered = registeredPhoto;
    final captured = capturedPath;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ComparePhoto(
            label: '등록 사진',
            image: registered == null || registered.isEmpty
                ? null
                : NetworkImage(Env.photoUrl(registered)),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 35, 10, 0),
          child: _VersusBadge(),
        ),
        Expanded(
          child: _ComparePhoto(
            label: '내가 찍은 사진',
            image: captured == null ? null : FileImage(File(captured)),
          ),
        ),
      ],
    );
  }
}

class _ComparePhoto extends StatelessWidget {
  const _ComparePhoto({required this.label, required this.image});

  final String label;
  final ImageProvider? image;

  static const double _height = 96;

  @override
  Widget build(BuildContext context) {
    final source = image;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: _height,
              width: double.infinity,
              child: source == null
                  ? const _EmptyPhoto()
                  : Image(
                      image: source,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (context, error, stackTrace) =>
                          const _EmptyPhoto(),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: AppTextStyles.badge.copyWith(color: AppColors.textDisabled),
        ),
      ],
    );
  }
}

/// 사진을 못 불러온 자리. 비는 것은 오류가 아니라 흔한 상태다.
class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.backgroundSubtle,
      child: Icon(
        Icons.person_rounded,
        size: 44,
        color: AppColors.primaryDisabled,
      ),
    );
  }
}

class _VersusBadge extends StatelessWidget {
  const _VersusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.backgroundSubtle,
        shape: BoxShape.circle,
      ),
      child: Text(
        'vs',
        style: AppTextStyles.badge.copyWith(color: AppColors.textDisabled),
      ),
    );
  }
}
