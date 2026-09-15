/// 큰 숫자로 끊어 읽는 한 칸. `(3, '시간')`처럼 숫자와 단위가 분리돼 있다.
///
/// 긴급 배너는 숫자만 크게 키우고 단위는 작게 두기 때문에, 완성된 문자열
/// 하나로는 그릴 수 없다.
typedef ElapsedPart = ({int value, String unit});

/// 실종 후 경과 시간 표기(기능정의서 5.3).
///
/// **서버가 계산해 내려준 분 단위 값을 포맷하기만 한다.** 클라이언트가 현재
/// 시각으로 다시 계산하지 않는다(설계 결정 6번). 사용자가 리셋할 수 없는,
/// 사건의 사실이기 때문이다.
///
/// - 24시간 미만 → `3시간 12분`
/// - 24시간 이상 → `2일 5시간` (분은 버린다)
class ElapsedTime {
  const ElapsedTime({
    required this.days,
    required this.hours,
    required this.minutes,
  });

  /// 서버가 준 `elapsed_minutes`를 쪼갠다. 음수는 0으로 본다.
  factory ElapsedTime.fromMinutes(int totalMinutes) {
    final total = totalMinutes < 0 ? 0 : totalMinutes;

    return ElapsedTime(
      days: total ~/ _minutesPerDay,
      hours: (total % _minutesPerDay) ~/ 60,
      minutes: total % 60,
    );
  }

  static const int _minutesPerDay = 24 * 60;

  final int days;
  final int hours;
  final int minutes;

  /// 하루가 넘었다. 넘으면 분 단위를 적지 않는다.
  bool get isOverDay => days > 0;

  /// 표기에 실제로 쓰는 칸들. 최대 두 칸이고, 뒤 칸이 0이면 칸 자체가 없다.
  ///
  /// "2일 0시간"이나 "3시간 0분"은 사람이 쓰는 말이 아니다.
  List<ElapsedPart> get parts {
    if (isOverDay) {
      return [
        (value: days, unit: '일'),
        if (hours > 0) (value: hours, unit: '시간'),
      ];
    }

    if (hours > 0) {
      return [
        (value: hours, unit: '시간'),
        if (minutes > 0) (value: minutes, unit: '분'),
      ];
    }

    return [(value: minutes, unit: '분')];
  }

  /// 한 줄 표기. `3시간 12분` · `2일 5시간`.
  String get label =>
      parts.map((part) => '${part.value}${part.unit}').join(' ');

  /// 뱃지용 한 칸 표기. 가장 큰 단위만 남긴다. `3시간` · `2일`.
  String get shortLabel {
    final head = parts.first;
    return '${head.value}${head.unit}';
  }
}
