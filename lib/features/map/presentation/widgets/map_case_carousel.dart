import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elapsed_badge.dart';
import '../../../../core/widgets/missing_thumbnail.dart';
import '../../../missing/data/missing_case.dart';

/// 지도 아래 가로로 넘기는 사건 카드(F-5.1.5).
///
/// 카드를 넘기면 지도가 그 사건으로 움직이고, 핀을 누르면 카드가 따라온다.
/// 지도와 목록이 서로를 따라다녀야 "이 핀이 누구인지"를 두 번 찾지 않는다.
class MapCaseCarousel extends StatelessWidget {
  const MapCaseCarousel({
    required this.cases,
    required this.controller,
    required this.onPageChanged,
    this.onTapCase,
    super.key,
  });

  final List<MissingCaseSummary> cases;

  /// 화면이 들고 있는 컨트롤러. 핀을 눌렀을 때 화면이 페이지를 옮긴다.
  final PageController controller;

  final ValueChanged<int> onPageChanged;
  final void Function(MissingCaseSummary summary)? onTapCase;

  /// 카드 높이. 지도 아래 공간을 이만큼 비워둔다.
  static const double height = 92;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onPageChanged,
        padEnds: false,
        itemCount: cases.length,
        itemBuilder: (context, index) {
          final summary = cases[index];

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _CaseCard(
              summary: summary,
              onTap: onTapCase == null ? null : () => onTapCase!(summary),
            ),
          );
        },
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.summary, this.onTap});

  final MissingCaseSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              MissingThumbnail(
                photoPath: summary.thumbnail,
                width: 46,
                height: 56,
                radius: 11,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            summary.name,
                            style: AppTextStyles.subtitle0.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          summary.ageGenderLabel,
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textDisabled,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (summary.distanceKm != null) ...[
                          Text(
                            _distanceLabel(summary.distanceKm!),
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        ElapsedBadge(
                          elapsedMinutes: summary.elapsedMinutes,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카드가 좁아 목록보다 짧게 적는다.
String _distanceLabel(double km) {
  if (km < 1) return '${(km * 1000).round()}m';
  if (km >= 10) return '${km.round()}km';

  return '${km.toStringAsFixed(1)}km';
}
