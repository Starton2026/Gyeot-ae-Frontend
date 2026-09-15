import '../../../core/format/elapsed_time.dart';
import '../../report/data/report.dart';

/// 제보 사이가 이만큼 끊기면 타임라인에 공백을 적는다(F-3.5.6).
const int timelineGapMinutes = 60;

/// `⋯ 1시간 20분 공백`. 공백이라 부를 만큼 끊기지 않았으면 null.
///
/// 서버의 `gap_minutes`는 경로상 바로 앞 지점(없으면 최초 실종) 기준이다. 보호자에게
/// "이 사이에는 아무도 못 봤다"는 것도 정보다 — 수색을 넓힐 구간이다.
String? timelineGapLabel(Report report) {
  final gap = report.gapMinutes;
  if (gap == null || gap < timelineGapMinutes) return null;

  return '⋯ ${ElapsedTime.fromMinutes(gap).label} 공백';
}

/// `↘ 남동쪽 1.4km`. 경로에 든 제보만 방향이 온다. 모르면 null(F-3.5.7).
///
/// 경로 번호가 없는 제보는 서버가 방향을 주지 않는다. 믿기 어려운 점에서
/// "어디로 갔다"고 적으면 그 말이 사실처럼 읽힌다.
String? timelineMovementLabel(Report report) {
  final direction = _directions[report.bearing];
  final km = report.distanceFromPrevKm;
  if (direction == null || km == null) return null;

  // 0.1km도 안 움직였으면 방향이 의미 없다. GPS 오차 안이다.
  if (km < 0.1) return '앞 지점 근처';

  return '${direction.arrow} ${direction.name} ${km.toStringAsFixed(1)}km';
}

const Map<String, ({String arrow, String name})> _directions = {
  'N': (arrow: '↑', name: '북쪽'),
  'NE': (arrow: '↗', name: '북동쪽'),
  'E': (arrow: '→', name: '동쪽'),
  'SE': (arrow: '↘', name: '남동쪽'),
  'S': (arrow: '↓', name: '남쪽'),
  'SW': (arrow: '↙', name: '남서쪽'),
  'W': (arrow: '←', name: '서쪽'),
  'NW': (arrow: '↖', name: '북서쪽'),
};
