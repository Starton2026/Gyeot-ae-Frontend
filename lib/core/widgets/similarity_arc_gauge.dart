import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/report/data/report.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 유사도 반원 게이지 + 등급 라벨(F-4.1.1·F-4.1.2).
///
/// S4-1 분석 결과 시트와 S0 온보딩이 같은 그림을 쓴다. 온보딩에서 본 것을
/// 제보할 때 그대로 만나야 "아까 그거"로 읽힌다.
///
/// 이 화면에서 가장 먼저 눈에 들어와야 하는 것이 숫자다. 목격자가 알고 싶은
/// 것은 "내가 본 사람이 맞나"이고, 그 답이 몇 퍼센트인지 한 번에 읽혀야 한다.
///
/// 색만으로 등급을 나누지 않는다. 숫자·색·글자 세 가지로 같은 것을 말한다
/// (비기능 요건 · 접근성).
class SimilarityArcGauge extends StatelessWidget {
  const SimilarityArcGauge({
    required this.similarity,
    required this.grade,
    super.key,
  });

  /// 0~100. null이면 얼굴 미검출이라 채울 것이 없다.
  final double? similarity;

  final SimilarityGrade grade;

  /// 시안 값. 반지름 72 반원에 굵기 14가 들어가는 크기다.
  static const double _width = 176;
  static const double _height = 96;

  Color get _color => switch (grade) {
    SimilarityGrade.high => AppColors.gradeHigh,
    SimilarityGrade.medium => AppColors.gradeMedium,
    SimilarityGrade.low => AppColors.gradeLow,
    SimilarityGrade.noFace => AppColors.gradeNoFace,
  };

  @override
  Widget build(BuildContext context) {
    final value = similarity;

    return Column(
      children: [
        SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomPaint(
                size: const Size(_width, _height),
                painter: _ArcPainter(
                  fraction: (value ?? 0) / 100,
                  color: _color,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    // 얼굴을 못 찾았으면 숫자가 없다. 0%가 아니다.
                    value == null ? '—' : '${value.round()}',
                    style: AppTextStyles.gauge.copyWith(color: _color),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      '%',
                      style: AppTextStyles.subtitle0.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 4, 11, 4),
            child: Text(
              grade.analysisHeadline,
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.fraction, required this.color});

  /// 0~1. 반원 중 채우는 비율.
  final double fraction;

  final Color color;

  static const double _stroke = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - _stroke) / 2;
    final center = Offset(size.width / 2, size.height - _stroke / 2 - 1);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.border;

    canvas.drawArc(rect, math.pi, math.pi, false, track);

    if (fraction <= 0) return;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * fraction.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) {
    return oldDelegate.fraction != fraction || oldDelegate.color != color;
  }
}
