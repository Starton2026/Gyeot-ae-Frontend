import 'package:flutter/material.dart';

/// 곁애 색 토큰. 디자인 시스템(Figma)에서 내려온 값이 원본이다.
///
/// 여기 없는 색을 임의로 추가하지 않는다. 브랜드 5색은 CLAUDE.md의
/// 설계 결정 9번, 유사도 등급 색은 기능정의서 5.2가 원본이다.
///
/// `features/` 코드에서 `Color(0x...)` 리터럴 대신 이 상수를 쓴다.
class AppColors {
  const AppColors._();

  // ── 브랜드 5색 ──────────────────────────────────────────────
  // 아래 시맨틱 색들이 이 값을 가리킨다. 브랜드색이 바뀌면 같이 따라간다.

  /// 신뢰·안전.
  static const Color brandTrust = Color(0xFF3B6CB7);

  /// 연결·기술.
  static const Color brandConnection = Color(0xFF7FB3FF);

  /// 관심·따뜻함.
  static const Color brandCare = Color(0xFFFF7E7E);

  /// 배려·희망.
  static const Color brandHope = Color(0xFFFFE5E1);

  /// 균형·신뢰감.
  static const Color brandReliability = Color(0xFFDEE6F0);

  // ── 액션 ───────────────────────────────────────────────────

  /// 메인 버튼, 주요 액션, 활성 상태. [brandTrust]와 같은 값.
  static const Color primary = brandTrust;

  /// 버튼 터치/클릭 상태.
  static const Color primaryPressed = Color(0xFF2F5A9D);

  /// 비활성 버튼, 비활성 UI.
  static const Color primaryDisabled = Color(0xFFA9BFE0);

  /// 포인트, CTA, 관심/강조 요소. [brandCare]와 같은 값.
  static const Color accent = brandCare;

  // ── 텍스트 (기본) ───────────────────────────────────────────
  // 본문에는 이 계열을 쓴다. 파랑기가 밀어 브랜드 톤과 붙는다.

  /// 제목, 핵심 텍스트.
  static const Color textPrimary = Color(0xFF1F2937);

  /// 본문, 설명, 보조 텍스트.
  static const Color textSecondary = Color(0xFF667085);

  /// Placeholder, 비활성 텍스트.
  static const Color textDisabled = Color(0xFFA8B0BC);

  /// 관심·강조 텍스트. [accent] 위에 글자를 올릴 때 쓰는 진한 짝.
  static const Color textCareAccent = Color(0xFFC9504F);

  // ── 텍스트 (중립) ───────────────────────────────────────────
  // 브랜드 톤을 빼야 하는 자리에만 쓴다. 기본은 위의 text* 계열이다.

  static const Color neutralTextBlack = Color(0xFF111111);
  static const Color neutralTextDarkGray = Color(0xFF505050);
  static const Color neutralTextLightGray = Color(0xFF767676);
  static const Color neutralTextPlaceholder = Color(0xFFAAAAAA);

  /// 디자인 토큰 이름은 `Text/Sub/gray`지만 글자색이 아니라 옅은 배경 회색이다.
  static const Color neutralGray = Color(0xFFF3F3F3);

  // ── 배경 ───────────────────────────────────────────────────

  /// 기본 앱 배경, 카드.
  static const Color background = white;

  /// 섹션 배경, 리스트 배경.
  static const Color backgroundSubtle = Color(0xFFF6F8FB);

  // ── 테두리 ─────────────────────────────────────────────────

  /// Input, Card, Divider. [brandReliability]와 같은 값.
  static const Color border = brandReliability;

  /// 브랜드 톤이 없는 중립 테두리.
  static const Color borderNeutral = Color(0xFFDEDEDE);

  // ── 정보 뱃지 ──────────────────────────────────────────────

  /// 연결색 계열의 옅은 배경. 제보 수처럼 사실만 알리는 뱃지에 쓴다.
  ///
  /// 브랜드 5색에는 없지만 [brandConnection]을 흰색 쪽으로 민 파생색이다.
  /// 경과 시간 뱃지(관심색·배려색)와 색 계열을 갈라놔야 둘이 나란히 있을 때
  /// 급한 것과 안 급한 것이 구분된다.
  ///
  /// 글자는 [primary]를 얹는다. 디자인 원본대로 [brandConnection]을 올리면
  /// 대비가 1.9:1이라 11px 글자가 읽히지 않는다.
  static const Color brandConnectionSurface = Color(0xFFEAF2FF);

  // ── 상태 ───────────────────────────────────────────────────

  /// 완료, 성공, 정상. 발견 완료 표시에 쓴다.
  static const Color success = Color(0xFF35A77A);

  /// 주의, 경고.
  static const Color warning = Color(0xFFE9A23B);

  /// 오류, 삭제, 실패.
  static const Color error = Color(0xFFE45D68);

  // ── 기본 ───────────────────────────────────────────────────

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ── 유사도 등급 (기능정의서 5.2) ─────────────────────────────

  /// 70% 이상. 경로 번호 O, 타임라인 기본 표시.
  static const Color gradeHigh = brandTrust;

  /// 40 ~ 70%. 경로 번호 O, 타임라인 기본 표시.
  static const Color gradeMedium = brandConnection;

  /// 40% 미만. 번호 없이 점, 점선·흐림, "확인 필요".
  ///
  /// 브랜드 5색에 없는 중립 파생색이다. 기능정의서 5.2가 지정한 값이라 그대로 둔다.
  static const Color gradeLow = Color(0xFFB3C2D4);

  /// 얼굴 미검출. [gradeLow]와 같은 색, 문구만 "얼굴 미검출".
  static const Color gradeNoFace = gradeLow;
}
