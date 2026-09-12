import 'package:flutter/material.dart';

import '../../features/missing/data/missing_case.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'elapsed_badge.dart';
import 'missing_thumbnail.dart';

/// 목록에 한 줄로 뜨는 사건. S1 주변 사건과 S2 목록이 같은 모양을 쓴다.
///
/// 발견 완료된 사건은 지우지 않고 투명도만 낮춘다(설계 결정 7번).
class MissingCaseTile extends StatelessWidget {
  const MissingCaseTile({required this.summary, this.onTap, super.key});

  final MissingCaseSummary summary;

  /// null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MissingThumbnail(
            photoPath: summary.thumbnail,
            width: 52,
            height: 60,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        summary.name,
                        style: AppTextStyles.title0,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      summary.ageGenderLabel,
                      style: AppTextStyles.body0.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  summary.description,
                  style: AppTextStyles.body0.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    if (summary.distanceKm != null) ...[
                      Text(
                        _distanceLabel(summary.distanceKm!),
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    ElapsedBadge(elapsedMinutes: summary.elapsedMinutes),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final tile = summary.status == CaseStatus.resolved
        ? Opacity(opacity: 0.48, child: content)
        : content;

    if (onTap == null) return tile;

    return InkWell(onTap: onTap, child: tile);
  }
}

/// `1.2km` · `12km`. 10km를 넘으면 소수점이 의미가 없다.
String _distanceLabel(double km) {
  if (km >= 10) return '${km.round()}km';

  return '${km.toStringAsFixed(1)}km';
}
