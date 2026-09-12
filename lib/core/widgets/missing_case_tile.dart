import 'package:flutter/material.dart';

import '../../features/missing/data/missing_case.dart';
import '../format/time_label.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'elapsed_badge.dart';
import 'missing_thumbnail.dart';

/// 사건 카드의 밀도. 같은 카드를 화면에 따라 두 가지로 쓴다.
enum MissingCaseTileVariant {
  /// S1 홈. 주변 3건만 보여주는 자리라 썸네일이 작고 줄 수가 적다.
  compact,

  /// S2 목록. 마지막 목격 위치·시간과 제보 수까지 보여준다.
  detailed;

  bool get isDetailed => this == MissingCaseTileVariant.detailed;
}

/// 목록에 한 줄로 뜨는 사건. S1 주변 사건과 S2 목록이 같은 모양을 쓴다.
///
/// 발견 완료된 사건은 지우지 않고 투명도만 낮춘다(설계 결정 7번). 끝난 사건이
/// 남아야 "이 서비스로 찾았다"는 증거가 쌓이고, 제보자에게는 자기 참여가
/// 결과로 이어졌다는 확인이 된다.
class MissingCaseTile extends StatelessWidget {
  const MissingCaseTile({
    required this.summary,
    this.variant = MissingCaseTileVariant.compact,
    this.onTap,
    super.key,
  });

  final MissingCaseSummary summary;
  final MissingCaseTileVariant variant;

  /// null이면 누를 수 없는 상태로 그린다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final detailed = variant.isDetailed;
    final resolved = summary.status == CaseStatus.resolved;

    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: detailed ? 14 : 12),
      child: Row(
        crossAxisAlignment: detailed
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          MissingThumbnail(
            photoPath: summary.thumbnail,
            width: detailed ? 58 : 52,
            height: detailed ? 70 : 60,
            radius: detailed ? 13 : 12,
          ),
          SizedBox(width: detailed ? 13 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NameLine(summary: summary),
                SizedBox(height: detailed ? 4 : 3),
                Text(
                  summary.description,
                  style: AppTextStyles.body0.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detailed) ...[
                  const SizedBox(height: 3),
                  Text(
                    _lastSeenLabel(summary),
                    style: AppTextStyles.body0.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: detailed ? 8 : 7),
                _MetaLine(summary: summary, showReportCount: detailed),
              ],
            ),
          ),
        ],
      ),
    );

    final tile = resolved ? Opacity(opacity: 0.48, child: content) : content;

    if (onTap == null) return tile;

    return InkWell(onTap: onTap, child: tile);
  }
}

/// 이름 + 나이·성별.
class _NameLine extends StatelessWidget {
  const _NameLine({required this.summary});

  final MissingCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: AppTextStyles.body0.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// 거리 · 경과(또는 발견 완료) · 제보 수.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.summary, required this.showReportCount});

  final MissingCaseSummary summary;
  final bool showReportCount;

  @override
  Widget build(BuildContext context) {
    final resolved = summary.status == CaseStatus.resolved;
    final distanceKm = summary.distanceKm;

    return Wrap(
      spacing: 7,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 끝난 사건에 "1.2km"를 붙이면 아직 찾아야 할 것처럼 읽힌다.
        if (distanceKm != null && !resolved)
          Text(
            _distanceLabel(distanceKm),
            style: AppTextStyles.badge.copyWith(color: AppColors.primary),
          ),
        if (resolved)
          const _FlatBadge(
            label: '발견완료',
            background: AppColors.backgroundSubtle,
            foreground: AppColors.textDisabled,
          )
        else
          ElapsedBadge(elapsedMinutes: summary.elapsedMinutes),
        if (showReportCount && summary.reportCount > 0)
          _FlatBadge(
            label: '제보 ${summary.reportCount}',
            background: AppColors.brandConnectionSurface,
            foreground: AppColors.primary,
          ),
      ],
    );
  }
}

/// 경과 뱃지와 같은 모양의 단색 뱃지.
class _FlatBadge extends StatelessWidget {
  const _FlatBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: foreground),
      ),
    );
  }
}

/// `인천 남동구 구월동 · 오늘 오후 2시 40분`.
///
/// 끝난 사건은 시각을 떼고 날짜만 남긴다. 몇 시에 사라졌는지가 더는 단서가
/// 아니기 때문이다.
String _lastSeenLabel(MissingCaseSummary summary) {
  final when = summary.status == CaseStatus.resolved
      ? koreanDateLabel(summary.missingAt)
      : koreanDateTimeLabel(summary.missingAt);
  final where = _shortAddress(summary.lastAddress);

  return where == null ? when : '$where · $when';
}

/// 주소를 시·구·동까지만 남긴다.
///
/// 목록은 한 줄이라 "인천 남동구 구월동 로데오거리"는 끝이 잘린다. 상세한
/// 위치는 S3에서 보여준다.
String? _shortAddress(String? address) {
  if (address == null || address.isEmpty) return null;

  final parts = address.split(' ');
  if (parts.length <= 3) return address;

  return parts.take(3).join(' ');
}

/// `280m` · `1.2km` · `12km`.
///
/// 1km가 안 되면 미터로 적는다. "0.3km"는 가까운지 먼지 바로 읽히지 않는다.
/// 10km를 넘으면 소수점이 의미가 없다.
String _distanceLabel(double km) {
  if (km < 1) return '${(km * 1000).round()}m';
  if (km >= 10) return '${km.round()}km';

  return '${km.toStringAsFixed(1)}km';
}
