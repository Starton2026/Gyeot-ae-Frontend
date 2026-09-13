import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 점선 테두리 상자.
///
/// 아직 채워지지 않은 자리를 점선으로 그린다. 실선으로 두면 이미 채워진
/// 카드와 구분되지 않는다. 제보창의 사진·분석 자리(F-4.2·F-4.5)와 등록 폼의
/// 사진 추가 칸(F-7.2)이 같은 모양을 쓴다.
///
/// Flutter의 `Border`는 점선을 그리지 못해서 직접 그린다.
class DashedBox extends StatelessWidget {
  const DashedBox({
    required this.child,
    this.radius = 15,
    this.color = AppColors.border,
    super.key,
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: radius, color: color),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  /// 선 5, 빈 곳 4. CSS `dashed`와 눈으로 비슷해지는 비율이다.
  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;

    for (final metric in path.computeMetrics()) {
      var start = 0.0;

      while (start < metric.length) {
        final end = math.min(start + _dash, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.color != color;
  }
}
