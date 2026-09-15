import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 지도 핀의 긴급도 단계(F-5.1.4).
///
/// 급한 사건일수록 크고 진하다. 오래된 사건은 회색으로 가라앉되
/// **사라지지는 않는다.**
///
/// 시안에는 골든타임 핀 주위에 옅은 링이 있었지만, 실기기에서 회색 얼룩처럼
/// 보여서 뺐다. 크기와 색만으로 충분히 갈린다.
enum MapPinLevel {
  /// 골든타임(3시간) 안.
  golden(pinWidth: 32, pinHeight: 40, color: AppColors.accent),

  /// 12시간 안.
  half(pinWidth: 26, pinHeight: 33, color: AppColors.accent),

  /// 그 밖.
  calm(pinWidth: 22, pinHeight: 28, color: AppColors.gradeLow);

  const MapPinLevel({
    required this.pinWidth,
    required this.pinHeight,
    required this.color,
  });

  final double pinWidth;
  final double pinHeight;
  final Color color;

  /// 그림 크기. 핀 끝이 맨 아래라 앵커가 늘 (0.5, 1.0)이고, 그 끝이 실제
  /// 좌표를 가리킨다.
  Size get canvasSize => Size(pinWidth, pinHeight);

  /// 서버가 준 경과 분으로 단계를 정한다(설계 결정 6번).
  static MapPinLevel of(int elapsedMinutes) {
    if (elapsedMinutes < 180) return MapPinLevel.golden;
    if (elapsedMinutes < 720) return MapPinLevel.half;

    return MapPinLevel.calm;
  }
}

/// 지도에 찍는 실종 위치 핀.
///
/// 이 위젯은 화면에 직접 붙이지 않고 `KImage.fromWidget`으로 구워서 지도에
/// 올린다. 그래야 핀도 브랜드 색을 그대로 쓰고, 이미지 파일을 단계마다
/// 따로 관리하지 않아도 된다.
class MapPinIcon extends StatelessWidget {
  const MapPinIcon({required this.level, super.key});

  final MapPinLevel level;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: level.canvasSize,
      painter: _PinPainter(color: level.color),
    );
  }
}

/// 물방울 모양 핀. 아래 끝이 좌표를 가리킨다.
class _PinPainter extends CustomPainter {
  const _PinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final radius = width / 2;
    final center = Offset(radius, radius);

    final path = Path()
      ..moveTo(radius, height)
      ..quadraticBezierTo(0, height * 0.52, 0, radius)
      ..arcToPoint(Offset(width, radius), radius: Radius.circular(radius))
      ..quadraticBezierTo(width, height * 0.52, radius, height)
      ..close();

    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = AppColors.white,
      )
      ..drawCircle(center, radius * 0.34, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.color != color;
}
