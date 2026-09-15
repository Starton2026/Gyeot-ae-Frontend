import '../../features/report/data/report.dart';
import '../location/location_source.dart';
import '../widgets/map_pin_icon.dart';

/// 보기 전용 지도에 찍을 것 하나.
///
/// 지도(플랫폼 뷰)와 떼어 두는 이유는, 무엇을 찍을지는 테스트할 수 있어야
/// 하는데 카카오맵은 테스트 환경에서 뜨지 않기 때문이다.
sealed class MapMark {
  const MapMark({required this.id, required this.at});

  final String id;
  final LocationFix at;

  /// 그림이 달라지는 값까지 담은 한 줄. 같으면 다시 그리지 않는다.
  String get signature;
}

/// 실종 위치 핀. 물방울 모양이다.
final class MissingMark extends MapMark {
  const MissingMark({
    required super.id,
    required super.at,
    required this.level,
  });

  final MapPinLevel level;

  @override
  String get signature => '$id@${at.lat},${at.lng}:${level.name}';
}

/// 제보 핀. 원이고, 경로에 든 제보만 번호가 있다.
final class ReportMark extends MapMark {
  const ReportMark({
    required super.id,
    required super.at,
    required this.grade,
    this.routeIndex,
  });

  final SimilarityGrade grade;
  final int? routeIndex;

  @override
  String get signature =>
      '$id@${at.lat},${at.lng}:${grade.wire}:${routeIndex ?? 0}';
}

/// 보기 전용 지도 한 장의 계획. 홈(S1)·상세(S3)가 만들고 `StaticKakaoMap`이 그린다.
class MapPlan {
  const MapPlan({
    required this.center,
    required this.zoomLevel,
    this.marks = const [],
    this.route = const [],
    this.fitMarks = false,
  });

  /// 카메라가 비출 자리. [fitMarks]로 맞출 핀이 모자라면 여기를 쓴다.
  final LocationFix center;
  final int zoomLevel;

  final List<MapMark> marks;

  /// 이동 경로. 두 점이 안 되면 선을 긋지 않는다.
  final List<LocationFix> route;

  /// 핀이 전부 들어오게 카메라를 맞춘다. 핀이 둘 이상일 때만 뜻이 있다.
  final bool fitMarks;

  /// 계획 전체를 한 줄로. 같으면 지도에 손대지 않는다 — 다시 그리면 핀이 깜빡인다.
  String get signature => [
    '${center.lat},${center.lng}@$zoomLevel:$fitMarks',
    for (final mark in marks) mark.signature,
    '|',
    for (final point in route) '${point.lat},${point.lng}',
  ].join(';');
}
