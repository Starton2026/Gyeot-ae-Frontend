import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';

/// 등록 사진 캐러셀(F-3.1).
///
/// 인디케이터와 카운터를 함께 둔다. 점만으로는 몇 장인지 세기 어렵고, 숫자만
/// 있으면 지금 어디쯤인지 감이 오지 않는다.
class DetailPhotoCarousel extends StatefulWidget {
  const DetailPhotoCarousel({
    required this.photos,
    required this.height,
    super.key,
  });

  /// 등록 사진. 비어 있으면 사람 실루엣 한 장을 대신 그린다.
  final List<String> photos;

  final double height;

  @override
  State<DetailPhotoCarousel> createState() => _DetailPhotoCarouselState();
}

class _DetailPhotoCarouselState extends State<DetailPhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final count = photos.isEmpty ? 1 : photos.length;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: count,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => MissingThumbnail(
              photoPath: photos.isEmpty ? null : photos[index],
              width: double.infinity,
              height: widget.height,
              radius: 0,
            ),
          ),
          if (count > 1) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: _Dots(count: count, current: _index),
            ),
            Positioned(
              right: 14,
              bottom: 11,
              child: _Counter(current: _index + 1, total: count),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++) ...[
          if (index > 0) const SizedBox(width: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == current ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(
                alpha: index == current ? 1 : 0.55,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$current / $total',
        style: AppTextStyles.small.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
