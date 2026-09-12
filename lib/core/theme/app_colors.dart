import 'package:flutter/material.dart';

/// 곁애 브랜드 색과 유사도 등급 색.
///
/// 여기 없는 색을 임의로 추가하지 않는다. 브랜드 5색은 CLAUDE.md의
/// 설계 결정 9번, 등급 색은 기능정의서 5.2가 원본이다.
///
/// `features/` 코드에서 `Color(0x...)` 리터럴 대신 이 상수를 쓴다.
class AppColors {
  const AppColors._();

  // ── 브랜드 5색 ──────────────────────────────────────────────

  /// 신뢰·안전. 주요 액션, 유사도 높음.
  static const Color trust = Color(0xFF3B6CB7);

  /// 연결·기술. AI 분석, 유사도 보통.
  static const Color connect = Color(0xFF7FB3FF);

  /// 관심·따뜻함. 긴급 배너, 마스코트.
  static const Color care = Color(0xFFFF7E7E);

  /// 배려·희망. 보호자 바로가기 띠 배경.
  static const Color hope = Color(0xFFFFE5E1);

  /// 균형·신뢰감. 구분선, 비활성 배경.
  static const Color balance = Color(0xFFDEE6F0);

  // ── 유사도 등급 (기능정의서 5.2) ─────────────────────────────

  /// 70% 이상. 경로 번호 O, 타임라인 기본 표시.
  static const Color gradeHigh = trust;

  /// 40 ~ 70%. 경로 번호 O, 타임라인 기본 표시.
  static const Color gradeMedium = connect;

  /// 40% 미만. 번호 없이 점, 점선·흐림, "확인 필요".
  ///
  /// 브랜드 5색에 없는 중립 파생색이다. 기능정의서 5.2가 지정한 값이라 그대로 둔다.
  static const Color gradeLow = Color(0xFFB3C2D4);

  /// 얼굴 미검출. [gradeLow]와 같은 색, 문구만 "얼굴 미검출".
  static const Color gradeNoFace = gradeLow;
}
