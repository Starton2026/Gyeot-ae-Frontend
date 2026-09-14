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

/// 날짜를 한국어로 읽는다. `오늘` · `어제` · `9월 9일`.
///
/// 시각이 아니라 **날짜**로 가른다. 자정을 막 넘긴 제보는 몇 시간 전이어도
/// "오늘"이 아니라 "어제"다.
///
/// [relative]를 false로 주면 오늘·어제로 줄이지 않고 늘 `9월 11일`로 적는다.
/// 실종 일시처럼 사건의 기록으로 읽는 값에 쓴다.
///
/// [now]는 테스트에서만 넘긴다.
String koreanDateLabel(DateTime time, {DateTime? now, bool relative = true}) {
  if (!relative) return '${time.month}월 ${time.day}일';

  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(time);
  final diffDays = today.difference(target).inDays;

  if (diffDays == 0) return '오늘';
  if (diffDays == 1) return '어제';

  return '${time.month}월 ${time.day}일';
}

/// `오늘 오후 2시 40분` · `9월 9일 오후 6시`.
String koreanDateTimeLabel(
  DateTime time, {
  DateTime? now,
  bool relative = true,
}) {
  final date = koreanDateLabel(time, now: now, relative: relative);

  return '$date ${koreanTimeLabel(time)}';
}

DateTime _dateOnly(DateTime time) => DateTime(time.year, time.month, time.day);

/// 얼마 전인지. `방금` · `12분 전` · `3시간 전` · `어제 오후 2시`.
///
/// 알림처럼 **새것인지가 중요한 자리**에 쓴다. 오늘 안이면 몇 분·몇 시간 전으로,
/// 날짜가 넘어가면 [koreanDateTimeLabel]로 적는다. "27시간 전"은 셈을 시킨다.
///
/// 폰 시계가 서버보다 조금 늦어 앞선 시각이 오면 `방금`으로 둔다.
String koreanAgoLabel(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);

  if (diff.inMinutes < 1) return '방금';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (_dateOnly(current) == _dateOnly(time)) return '${diff.inHours}시간 전';

  return koreanDateTimeLabel(time, now: current);
}

/// 시각을 짧게 읽는다. `오후 2:40`.
///
/// 시간 슬라이더처럼 폭이 좁아 `오후 2시 40분`이 들어가지 않는 자리에 쓴다.
String koreanClockLabel(DateTime time) {
  final isMorning = time.hour < 12;
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');

  return '${isMorning ? '오전' : '오후'} $hour12:$minute';
}
