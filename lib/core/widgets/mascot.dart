import 'package:flutter/material.dart';

/// 마스코트 이음이의 포즈. 포즈마다 쓰는 자리가 정해져 있다.
///
/// 이음이는 **사건이 진행 중인 화면에서 물러난다**(설계 결정 8번).
/// 긴급 배너·실종자 등록 폼·AI 분석 결과·지도 이동 경로·제보 타임라인에는
/// 쓰지 않는다. 기다림과 안도의 순간에만 등장한다.
enum MascotPose {
  /// 기본 포즈.
  basic('ieumi.png'),

  /// 찾아요. 급한 사건이 없는 홈, 검색 결과 없음.
  find('ieumi_find.png'),

  /// 함께해요. 제보 완료.
  together('ieumi_together.png'),

  /// 달려가요. 제보 전송 중.
  run('ieumi_run.png'),

  /// 연결해요. 온보딩, 지도 안내.
  connect('ieumi_connect.png');

  const MascotPose(this._fileName);

  final String _fileName;

  /// `assets/characters/` 아래의 파일 경로.
  String get asset => 'assets/characters/$_fileName';
}

/// 마스코트 이음이 그림 한 장.
///
/// ```dart
/// Mascot(MascotPose.find, height: 75)
/// ```
class Mascot extends StatelessWidget {
  const Mascot(this.pose, {this.height = 72, super.key});

  final MascotPose pose;

  /// 세로 길이. 가로는 그림 비율을 따라간다.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      pose.asset,
      height: height,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
