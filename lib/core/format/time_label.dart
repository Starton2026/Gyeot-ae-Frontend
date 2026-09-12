/// 시각을 한국어로 읽는다. `오후 2시 40분`.
///
/// `intl`의 `DateFormat`을 쓰지 않는 이유는, 'ko' 로케일 데이터를 앱 시작 시
/// `initializeDateFormatting`으로 따로 불러와야 하고, 그걸 잊은 화면·테스트에서
/// 런타임 예외가 나기 때문이다. 이 표기는 규칙이 네 줄이라 직접 적는 쪽이 안전하다.
///
/// 0분이면 분을 적지 않는다. "오후 2시 0분"이라고 말하는 사람은 없다.
String koreanTimeLabel(DateTime time) {
  final isMorning = time.hour < 12;
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final meridiem = isMorning ? '오전' : '오후';

  if (time.minute == 0) return '$meridiem $hour12시';

  return '$meridiem $hour12시 ${time.minute}분';
}
