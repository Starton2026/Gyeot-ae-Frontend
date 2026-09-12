import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../map_providers.dart';

/// 사건 선택 모드의 하단 패널(F-5.2.3 ~ F-5.2.6).
///
/// **시간 슬라이더가 이 화면의 주인공이라 가장 큰 면적을 준다.** 핀만 찍힌
/// 지도는 다른 서비스에도 있지만, 시간을 끌어 경로가 자라나는 것을 보여주는
/// 순간 "이동 경로 복원"이 눈으로 증명된다.
class MapRoutePanel extends StatelessWidget {
  const MapRoutePanel({
    required this.view,
    required this.highOnly,
    required this.onHighOnlyChanged,
    required this.onCursorChanged,
    super.key,
  });

  final MapCaseView view;
  final bool highOnly;
  final ValueChanged<bool> onHighOnlyChanged;

  /// 슬라이더를 끌 때마다 그 시각을 준다.
  final ValueChanged<DateTime> onCursorChanged;

  static const Key filterSwitchKey = Key('map_route_filter_switch');
  static const Key sliderKey = Key('map_route_slider');

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Handle(),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title(view),
                      style: AppTextStyles.subtitle0.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _FilterToggle(
                    value: highOnly,
                    onChanged: onHighOnlyChanged,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _TimeSlider(view: view, onChanged: onCursorChanged),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    '${koreanClockLabel(view.from)} 실종',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    view.isAtLatest
                        ? '${koreanClockLabel(view.cursor)} 현재'
                        : '${koreanClockLabel(view.cursor)} 까지',
                    style: AppTextStyles.small.copyWith(
                      color: view.isAtLatest
                          ? AppColors.textDisabled
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              const Divider(height: 1),
              const SizedBox(height: 11),
              const _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

String _title(MapCaseView view) {
  if (view.reports.isEmpty) return '아직 이 시점의 제보가 없어요';

  return '제보 ${view.reports.length}건으로 복원한 경로';
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

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
          '60% 이상',
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
              key: MapRoutePanel.filterSwitchKey,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// 실종 시각부터 최신 제보까지를 끄는 슬라이더(F-5.2.4).
///
/// 눈금은 **실제 제보가 있는 시각**에만 찍는다. 균등한 눈금은 정보가 없지만,
/// 제보 시각 눈금은 "언제 목격이 몰렸는지"를 그 자체로 보여준다.
class _TimeSlider extends StatelessWidget {
  const _TimeSlider({required this.view, required this.onChanged});

  final MapCaseView view;
  final ValueChanged<DateTime> onChanged;

  static const double _height = 28;

  @override
  Widget build(BuildContext context) {
    final span = view.to.difference(view.from).inMilliseconds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        void emit(double dx) {
          if (span <= 0) return;

          final ratio = (dx / width).clamp(0.0, 1.0);
          onChanged(
            view.from.add(Duration(milliseconds: (span * ratio).round())),
          );
        }

        return GestureDetector(
          key: MapRoutePanel.sliderKey,
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => emit(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => emit(details.localPosition.dx),
          child: SizedBox(
            height: _height,
            child: CustomPaint(
              painter: _SliderPainter(
                progress: span <= 0
                    ? 1
                    : view.cursor.difference(view.from).inMilliseconds / span,
                tickRatios: [
                  for (final tick in view.ticks)
                    if (span > 0) tick.difference(view.from).inMilliseconds / span,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  const _SliderPainter({required this.progress, required this.tickRatios});

  final double progress;
  final List<double> tickRatios;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final value = progress.clamp(0.0, 1.0);
    final knobX = size.width * value;

    final track = RRect.fromLTRBR(
      0,
      centerY - 2.5,
      size.width,
      centerY + 2.5,
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = AppColors.backgroundSubtle);

    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        centerY - 2.5,
        knobX,
        centerY + 2.5,
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.primary,
    );

    final tickPaint = Paint()
      ..color = AppColors.gradeLow
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final ratio in tickRatios) {
      final x = size.width * ratio.clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(x, centerY - 5.5),
        Offset(x, centerY + 5.5),
        tickPaint,
      );
    }

    canvas
      ..drawCircle(Offset(knobX, centerY), 9.5, Paint()..color = AppColors.white)
      ..drawCircle(
        Offset(knobX, centerY),
        8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.primary,
      );
  }

  @override
  bool shouldRepaint(covariant _SliderPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.tickRatios.length != tickRatios.length;
}

/// 핀 4종 설명(F-5.2.6).
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 13,
      runSpacing: 8,
      children: [
        _LegendItem(color: AppColors.accent, label: '실종 위치'),
        _LegendItem(color: AppColors.gradeHigh, label: '유사도 70%↑'),
        _LegendItem(color: AppColors.gradeMedium, label: '40~70%'),
        _LegendItem(color: AppColors.gradeLow, label: '확인 필요'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.badge.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
