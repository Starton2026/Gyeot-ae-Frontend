import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../report/data/report.dart';
import '../missing_detail_providers.dart';
import 'report_timeline_card.dart';

/// 제보 타임라인(F-3.5).
///
/// **최신이 위, 최초 실종이 맨 아래 고정**이다(F-3.5.1). 보호자가 보고 싶은
/// 것은 "지금 어디쯤인가"이기 때문이다. 번호는 지도 핀과 같은 시간순이라
/// 3, 2, 1로 내려가는 것이 의도된 방향이다.
class ReportTimeline extends StatelessWidget {
  const ReportTimeline({
    required this.view,
    required this.totalCount,
    required this.highOnly,
    required this.onHighOnlyChanged,
    this.origin,
    this.onToggleConfirmed,
    this.onToggleHidden,
    this.onShare,
    super.key,
  });

  /// 제보가 없을 때 공유 버튼이 부른다(F-3.5.15).
  final VoidCallback? onShare;

  /// 보호자만 준다. 카드마다 확인함·숨기기가 붙는다(F-3.5.13).
  final ValueChanged<Report>? onToggleConfirmed;
  final ValueChanged<Report>? onToggleHidden;

  /// 토글을 반영한 목록.
  final TimelineView view;

  /// 거르기 전 전체 제보 수. 헤더에 적는 숫자다.
  final int totalCount;

  final bool highOnly;
  final ValueChanged<bool> onHighOnlyChanged;

  final ReportOrigin? origin;

  static const Key filterSwitchKey = Key('timeline_filter_switch');
  static const Key emptyShareButtonKey = Key('timeline_empty_share');

  @override
  Widget build(BuildContext context) {
    final originPoint = origin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('제보 $totalCount건', style: AppTextStyles.title0),
            const Spacer(),
            _FilterToggle(value: highOnly, onChanged: onHighOnlyChanged),
          ],
        ),
        if (totalCount == 0)
          _EmptyTimeline(onShare: onShare)
        else ...[
          if (view.hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '유사도가 낮은 ${view.hiddenCount}건 숨김',
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          const SizedBox(height: 14),
          _Rail(
            children: [
              for (final report in view.shown)
                ReportTimelineCard.report(
                  report: report,
                  onToggleConfirmed: _bind(onToggleConfirmed, report),
                  onToggleHidden: _bind(onToggleHidden, report),
                ),
              if (originPoint != null)
                ReportTimelineCard.origin(origin: originPoint),
            ],
          ),
        ],
      ],
    );
  }

  static VoidCallback? _bind(ValueChanged<Report>? action, Report report) {
    if (action == null) return null;

    return () => action(report);
  }
}

/// 칸들을 잇는 점선 레일. 번호 배지 뒤로 지나간다.
class _Rail extends StatelessWidget {
  const _Rail({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: ReportTimelineCard.dotSize / 2 - 1,
          top: 6,
          bottom: 14,
          width: 2,
          child: CustomPaint(painter: _DashedRailPainter()),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ],
    );
  }
}

class _DashedRailPainter extends CustomPainter {
  const _DashedRailPainter();

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var y = 0.0; y < size.height; y += _dash + _gap) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + _dash).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRailPainter oldDelegate) => false;
}

/// "유사도 60% 이상" 토글(F-3.5.5).
class _FilterToggle extends StatelessWidget {
  const _FilterToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '유사도 60% 이상',
          style: AppTextStyles.body0.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 4),
        // 기본 스위치는 이 줄에 비해 크다. 모양은 그대로 두고 크기만 줄인다.
        SizedBox(
          width: 40,
          height: 26,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch(
              key: ReportTimeline.filterSwitchKey,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// 제보가 한 건도 없을 때(F-3.5.15).
///
/// 실패가 아니라 안내의 자리라서 이음이가 나와도 된다(설계 결정 8번).
class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({this.onShare});

  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Mascot(MascotPose.find, height: 86),
          const SizedBox(height: 14),
          const Text('아직 들어온 제보가 없어요', style: AppTextStyles.title0),
          const SizedBox(height: 6),
          Text(
            '공유하면 더 많은 사람이 볼 수 있어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (onShare != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: ReportTimeline.emptyShareButtonKey,
              onPressed: onShare,
              icon: const AppIcon(
                AppIcons.share,
                size: 15,
                color: AppColors.primary,
              ),
              label: const Text('카카오톡으로 공유하기'),
            ),
          ],
        ],
      ),
    );
  }
}
