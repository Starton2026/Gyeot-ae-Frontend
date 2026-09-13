import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 온보딩 1장의 그림. 흩어진 제보가 하나의 선으로 이어지는 장면.
///
/// **이 앱이 "제보 앱"이 아니라 "경로를 복원하는 앱"이라는 것**이 한 장에
/// 전달되어야 한다. 그래서 마스코트를 두지 않는다. 얼굴이 있으면 눈이 먼저
/// 그쪽으로 가고, 정작 읽어야 할 선과 번호가 안 읽힌다.
class RouteIllustration extends StatelessWidget {
  const RouteIllustration({super.key});

  static const Size _size = Size(240, 200);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _size,
      painter: _RoutePainter(
        numberStyle: AppTextStyles.badge.copyWith(
          color: AppColors.white,
          fontSize: 12,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.numberStyle});

  final TextStyle numberStyle;

  /// 실종 지점. 나머지는 제보 지점이다.
  static const Offset _origin = Offset(56, 142);

  static const List<Offset> _reports = [
    Offset(110, 112),
    Offset(164, 86),
    Offset(202, 54),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintMap(canvas);
    _paintRoute(canvas);
    _paintOriginPin(canvas);
    _paintReportPins(canvas);
  }

  /// 배경 지도. 블록과 길은 서로 다른 밝기여야 지도로 읽힌다.
  void _paintMap(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(14, 18, 212, 164),
        const Radius.circular(18),
      ),
      Paint()..color = AppColors.backgroundSubtle,
    );

    final blocks = Paint()..color = AppColors.brandConnectionSurface;
    for (final block in const [
      Rect.fromLTWH(28, 32, 60, 42),
      Rect.fromLTWH(98, 30, 52, 44),
      Rect.fromLTWH(160, 34, 52, 40),
      Rect.fromLTWH(30, 122, 56, 44),
      Rect.fromLTWH(96, 124, 56, 42),
      Rect.fromLTWH(162, 120, 50, 46),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(block, const Radius.circular(5)),
        blocks,
      );
    }

    final roads = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawLine(const Offset(18, 100), const Offset(222, 100), roads)
      ..drawLine(const Offset(92, 22), const Offset(92, 178), roads)
      ..drawLine(const Offset(156, 22), const Offset(156, 178), roads);
  }

  /// 점선으로 잇는다. 복원한 선이지 목격한 선이 아니다.
  void _paintRoute(Canvas canvas) {
    final path = Path()..moveTo(_origin.dx, _origin.dy + 6);
    for (final point in _reports) {
      path.lineTo(point.dx, point.dy);
    }

    final paint = Paint()
      ..color = AppColors.brandConnection
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = math.min(start + 8, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + 6;
      }
    }
  }

  /// 실종 지점. 물방울 모양은 지도 화면의 핀과 같다.
  void _paintOriginPin(Canvas canvas) {
    const radius = 16.2;
    final center = Offset(_origin.dx, _origin.dy);

    final pin = Path()
      ..moveTo(center.dx, center.dy + 26)
      ..quadraticBezierTo(
        center.dx - radius,
        center.dy + 8,
        center.dx - radius,
        center.dy,
      )
      ..arcToPoint(
        Offset(center.dx + radius, center.dy),
        radius: const Radius.circular(radius),
      )
      ..quadraticBezierTo(
        center.dx + radius,
        center.dy + 8,
        center.dx,
        center.dy + 26,
      )
      ..close();

    canvas
      ..drawPath(
        pin,
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawPath(pin, Paint()..color = AppColors.accent)
      ..drawCircle(center, 5.4, Paint()..color = AppColors.white);
  }

  /// 번호가 붙은 제보. 지도 핀 번호와 같은 숫자다.
  void _paintReportPins(Canvas canvas) {
    final ring = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;

    for (var index = 0; index < _reports.length; index++) {
      final center = _reports[index];

      // 첫 제보는 유사도가 낮았다가 뒤로 갈수록 확실해지는 모양으로 둔다.
      final fill = index == 0
          ? AppColors.gradeMedium
          : AppColors.gradeHigh;

      canvas
        ..drawCircle(center, 13, Paint()..color = fill)
        ..drawCircle(center, 13, ring);

      final label = TextPainter(
        text: TextSpan(text: '${index + 1}', style: numberStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      label.paint(
        canvas,
        center - Offset(label.width / 2, label.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.numberStyle != numberStyle;
}
