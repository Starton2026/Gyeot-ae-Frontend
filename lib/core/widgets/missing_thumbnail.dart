import 'package:flutter/material.dart';

import '../config/env.dart';
import '../theme/app_colors.dart';

/// 실종자 대표 사진. S1 긴급 배너·주변 목록, S2 목록, S3 상세, S5 지도 카드가
/// 크기만 바꿔 같은 모양을 쓴다.
///
/// 서버가 준 경로(`/uploads/xxx.jpg`)를 [Env.photoUrl]로 절대 URL로 바꿔 받는다.
/// 사진이 없거나 못 불러오면 사람 실루엣을 대신 그린다. 사진이 비는 것은
/// 오류가 아니라 흔한 상태다.
class MissingThumbnail extends StatelessWidget {
  const MissingThumbnail({
    required this.photoPath,
    required this.width,
    required this.height,
    this.radius = 12,
    super.key,
  });

  /// 서버가 준 사진 경로. null이면 실루엣만 그린다.
  final String? photoPath;

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: path == null || path.isEmpty
            ? const _EmptyPhoto()
            : Image.network(
                Env.photoUrl(path),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) =>
                    const _EmptyPhoto(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _EmptyPhoto(),
              ),
      ),
    );
  }
}

/// 사진이 없을 때 자리를 지키는 실루엣.
class _EmptyPhoto extends StatelessWidget {
  const _EmptyPhoto();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: AppColors.backgroundSubtle,
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: constraints.maxHeight * 0.62,
              color: AppColors.primaryDisabled,
            ),
          ),
        );
      },
    );
  }
}
