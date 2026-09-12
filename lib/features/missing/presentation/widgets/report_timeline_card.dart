import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../../core/widgets/similarity_gauge.dart';
import '../../../report/data/report.dart';

/// 타임라인의 한 칸. 번호 배지 + 카드.
///
/// 제보 한 건([ReportTimelineCard.report])과 맨 아래 고정되는 최초 실종
/// 지점([ReportTimelineCard.origin])이 같은 레일 위에 놓인다.
///
/// 유사도 40% 미만과 얼굴 미검출은 **지우지 않고** 점선 테두리·흐린 글자·
/// "확인 필요" 라벨로만 구분한다(설계 결정 3번, F-3.5.4). 옷을 갈아입었거나
/// 뒷모습만 찍힌 진짜 제보가 걸러지면 경로에 구멍이 생긴다.
class ReportTimelineCard extends StatelessWidget {
  const ReportTimelineCard.report({required Report this.report, super.key})
    : origin = null;

  const ReportTimelineCard.origin({
    required ReportOrigin this.origin,
    super.key,
  }) : report = null;

  final Report? report;
  final ReportOrigin? origin;

  /// 번호 배지 지름. 레일의 가로 위치를 여기에 맞춘다.
  static const double dotSize = 24;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _Dot(report: report),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: report == null
                ? _OriginCard(origin: origin!)
                : _ReportCard(report: report!),
          ),
        ],
      ),
    );
  }
}

/// 번호 배지(F-3.5.2). 지도의 핀 번호와 같은 숫자다.
///
/// 경로에 들어가지 못한 제보(40% 미만·미검출)는 번호 대신 점을 찍는다.
class _Dot extends StatelessWidget {
  const _Dot({this.report});

  final Report? report;

  @override
  Widget build(BuildContext context) {
    final item = report;
    final color = item == null ? AppColors.accent : _gradeColor(item.grade);

    return Container(
      width: ReportTimelineCard.dotSize,
      height: ReportTimelineCard.dotSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: AppColors.border, spreadRadius: 1.5),
        ],
      ),
      child: item == null
          ? const AppIcon(
              AppIcons.locationMarker,
              size: 11,
              color: AppColors.white,
            )
          : Text(
              item.routeIndex?.toString() ?? '·',
              style: AppTextStyles.badge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final uncertain = !report.grade.countsTowardPath;
    final place = report.placeName;

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: uncertain ? AppColors.backgroundSubtle : AppColors.background,
        borderRadius: BorderRadius.circular(15),
        border: uncertain
            ? null
            : Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: uncertain ? 0.6 : 1,
            child: MissingThumbnail(
              photoPath: report.photoUrl,
              width: 44,
              height: 52,
              radius: 10,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      koreanTimeLabel(report.observedAt),
                      style: AppTextStyles.subtitle0.copyWith(
                        color: uncertain
                            ? AppColors.textDisabled
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (report.grade == SimilarityGrade.low) ...[
                      const SizedBox(width: 7),
                      const _NeedCheckBadge(),
                    ],
                  ],
                ),
                if (place != null && place.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    place,
                    style: AppTextStyles.body0.copyWith(
                      color: uncertain
                          ? AppColors.textDisabled
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 7),
                SimilarityGauge(
                  similarity: report.similarity,
                  grade: report.grade,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!uncertain) return card;

    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(radius: 15),
      child: card,
    );
  }
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({required this.origin});

  final ReportOrigin origin;

  @override
  Widget build(BuildContext context) {
    final address = origin.address;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(koreanTimeLabel(origin.at), style: AppTextStyles.subtitle0),
          const SizedBox(height: 3),
          Text(
            address == null || address.isEmpty
                ? '최초 실종'
                : '최초 실종 · $address',
            style: AppTextStyles.body0.copyWith(
              color: AppColors.textCareAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedCheckBadge extends StatelessWidget {
  const _NeedCheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '확인 필요',
        style: AppTextStyles.small.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 점선 테두리. 저신뢰 제보를 지우지 않으면서 눈으로 구분하는 표시다.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius});

  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gradeLow;

    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

Color _gradeColor(SimilarityGrade grade) => switch (grade) {
  SimilarityGrade.high => AppColors.gradeHigh,
  SimilarityGrade.medium => AppColors.gradeMedium,
  SimilarityGrade.low || SimilarityGrade.noFace => AppColors.gradeLow,
};
