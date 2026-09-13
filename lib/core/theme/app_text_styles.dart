import 'package:flutter/material.dart';

/// 곁애 텍스트 스타일. 폰트는 Pretendard 하나만 쓴다.
///
/// 위젯에서 `TextStyle(fontSize: ...)`을 직접 만들지 말고 여기 있는 것을 쓴다.
/// 색은 넣지 않는다. 필요하면 `.copyWith(color: AppColors.textSecondary)`로 얹는다.
///
/// 줄간격(`height`)은 디자인 토큰에 아직 없어서 폰트 기본값을 따른다.
class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Pretendard';

  // ── 디자인 전달분 ───────────────────────────────────────────
  // Figma 스타일 이름과 1:1로 맞춘다. 이름을 코드에서 바꾸지 않는다.

  /// Bold 20. 화면 제목, 긴급 배너 헤드.
  static const TextStyle headline0 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: -0.3,
  );

  /// Regular 30. 가장 큰 제목. 온보딩·완료 화면.
  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 30,
    letterSpacing: 0,
  );

  /// Bold 24. 섹션 대제목.
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    letterSpacing: 1,
  );

  /// Bold 16. 카드 제목, 상단바 제목, 리스트 항목 이름.
  static const TextStyle title0 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    letterSpacing: -0.2,
  );

  /// SemiBold 14. 소제목, 항목 라벨.
  static const TextStyle subtitle0 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: -0.1,
  );

  /// Regular 12. 보조 설명.
  static const TextStyle body0 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Medium 12. 보조 설명 중 강조할 부분.
  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    letterSpacing: 0,
  );

  /// Regular 12. 캡션. 자간이 [body0]보다 넓다.
  static const TextStyle caption0 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
  );

  /// Regular 10. 가장 작은 글자. 보조 라벨.
  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 10,
    letterSpacing: 0.2,
  );

  // ── 코드 추가분 ─────────────────────────────────────────────
  // 전달받은 9종으로는 명세 화면을 덮지 못해 채운 것들이다.
  // 디자인에서 정식 토큰이 내려오면 그 값으로 교체한다.

  /// Medium 16. [title0]보다 약한 강조. 리스트 항목 이름, 강조 본문.
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    letterSpacing: -0.2,
  );

  /// Regular 16. 가장 큰 본문. 고령자 안내문, 긴 설명문.
  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.2,
  );

  /// Regular 14. 기본 본문.
  ///
  /// 전달분에는 14 Regular가 없고 14는 SemiBold([subtitle0])뿐이었다.
  /// 12는 이 서비스의 고령자 사용자에게 작다.
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.1,
  );

  /// SemiBold 16. 버튼 라벨. 버튼 높이 52에 맞춘다.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    letterSpacing: -0.2,
  );

  /// SemiBold 11. 경과 시간 뱃지, 유사도 등급 뱃지.
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 0,
  );

  /// Bold 40. 유사도 반원 게이지의 큰 숫자 (S4-1).
  ///
  /// 시안은 34지만 반원 안에서 더 커도 된다. 이 시트에서 목격자가 가장 먼저
  /// 알고 싶은 것이 이 숫자다.
  ///
  /// 숫자 폭을 고정해서(`tabularFigures`) 63%와 100%가 같은 리듬으로 읽힌다.
  static const TextStyle gauge = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 40,
    letterSpacing: -0.6,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Bold 20. 경과 시간 타이머 (S1 긴급 배너).
  ///
  /// 숫자 폭을 고정해서(`tabularFigures`) 초가 바뀔 때 글자가 흔들리지 않는다.
  static const TextStyle timer = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
