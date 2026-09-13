import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/report.dart';

/// 방금 보낸 제보 요약(F-4.2.2).
///
/// 유사도·위치·시간 세 줄. 보낸 뒤에 무엇이 갔는지 확인할 수 있어야, 잘못
/// 보냈다는 생각이 들 때 다시 제보할지 판단할 수 있다.
class ReportDoneSummary extends StatelessWidget {
  const ReportDoneSummary({
    required this.report,
    required this.address,
    super.key,
  });

  final Report report;

  /// 장소 이름을 안 적었을 때 대신 쓸 지역 이름.
  final String address;

  @override
  Widget build(BuildContext context) {
    final place = report.placeName;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              label: '유사도',
              child: _SimilarityChip(
                similarity: report.similarity,
                grade: report.grade,
              ),
            ),
            const SizedBox(height: 10),
            _Row(
              label: '위치',
              child: Text(
                // 좌표 없이 보낸 제보에 지역 이름을 적으면 거기서 본 것이
                // 된다. 없으면 없다고 적는다.
                !report.hasLocation
                    ? '위치 없이 보냄'
                    : (place == null || place.isEmpty ? address : place),
                style: AppTextStyles.subtitle1.copyWith(
                  color: report.hasLocation
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            _Row(
              label: '시간',
              child: Text(
                koreanDateTimeLabel(report.observedAt),
                style: AppTextStyles.subtitle1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: AppTextStyles.subtitle0.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

/// `63% · 보통`. 얼굴을 못 찾았으면 등급 이름만 적는다.
class _SimilarityChip extends StatelessWidget {
  const _SimilarityChip({required this.similarity, required this.grade});

  final double? similarity;
  final SimilarityGrade grade;

  /// 경로에 들어간 제보만 파란 칩이다. 낮거나 얼굴을 못 찾은 제보까지 같은
  /// 색으로 적으면, 보낸 사람이 실제보다 확실한 단서를 준 것으로 읽는다.
  bool get _onPath => grade.countsTowardPath;

  @override
  Widget build(BuildContext context) {
    final value = similarity;

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _onPath
              ? AppColors.brandConnectionSurface
              : AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
          child: Text(
            value == null
                ? grade.displayLabel
                : '${value.round()}% · ${grade.displayLabel}',
            style: AppTextStyles.badge.copyWith(
              color: _onPath ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
