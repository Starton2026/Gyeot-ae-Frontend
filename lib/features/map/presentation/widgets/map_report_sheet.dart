import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../../core/widgets/similarity_gauge.dart';
import '../../../report/data/report.dart';

/// 지도에서 제보 핀을 눌렀을 때 뜨는 미니 카드(F-5.2.7).
///
/// 사진·시각·유사도만 보여준다. 지도를 덮지 않을 만큼만 올라와야 방금 누른
/// 핀이 어디였는지 잊지 않는다.
Future<void> showMapReportSheet(
  BuildContext context, {
  required Report report,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    builder: (context) => _MapReportSheet(report: report),
  );
}

class _MapReportSheet extends StatelessWidget {
  const _MapReportSheet({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final place = report.placeName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MissingThumbnail(
              photoPath: report.photoUrl,
              width: 62,
              height: 74,
              radius: 12,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        koreanTimeLabel(report.observedAt),
                        style: AppTextStyles.title0,
                      ),
                      if (report.routeIndex != null) ...[
                        const SizedBox(width: 7),
                        Text(
                          '경로 ${report.routeIndex}번',
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place == null || place.isEmpty
                        ? koreanDateLabel(report.observedAt)
                        : place,
                    style: AppTextStyles.body0.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  SimilarityGauge(
                    similarity: report.similarity,
                    grade: report.grade,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
