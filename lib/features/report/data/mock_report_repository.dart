import 'dart:math' as math;

import '../../../core/mock/mock_backend.dart';
import '../../../core/network/api_exception.dart';
import 'analysis.dart';
import 'report.dart';
import 'report_repository.dart';

/// 백엔드 없이 도는 [ReportRepository].
///
/// 제보를 확정하면 저장소에 쌓이고 경로가 다시 계산된다. S4에서 제보한 것이
/// S3 타임라인에 바로 나타나서, 백엔드 없이도 핵심 루프를 끝까지 시연할 수 있다.
class MockReportRepository implements ReportRepository {
  MockReportRepository(
    this._backend, {
    this.latency = const Duration(milliseconds: 450),
  });

  final MockBackend _backend;

  /// 일부러 주는 지연. 분석은 실제로도 몇 초 걸려서 더 길게 준다.
  final Duration latency;

  @override
  Future<AnalysisResult> analyze({
    required String missingId,
    required String photoPath,
  }) async {
    await _delay(latency * 2);

    if (_backend.findCase(missingId) == null) throw _notFound();

    return AnalysisResult.fromJson(_backend.createAnalysis(missingId));
  }

  @override
  Future<Report> submit({
    required String analysisId,
    required double lat,
    required double lng,
    required DateTime observedAt,
    String? placeName,
  }) async {
    await _delay(latency);

    final analysis = _backend.consumeAnalysis(analysisId);
    if (analysis == null) {
      throw const ApiException(
        '분석 결과가 만료되었습니다. 다시 분석해 주세요.',
        statusCode: 410,
        code: ApiErrorCode.analysisExpired,
      );
    }

    final created = _backend.addReport(
      analysis: analysis,
      lat: lat,
      lng: lng,
      observedAt: observedAt,
      placeName: placeName,
    );

    // 번호는 저장 후 전체를 다시 매긴다. 목격 시각이 앞서는 제보가 뒤늦게
    // 올라오면 그 사이에 끼어들어야 한다(설계 결정 5번).
    final missingId = analysis['missing_id'] as String;
    final enriched = _enrich(_backend.reportsFor(missingId), missingId);
    final stored = enriched.firstWhere(
      (report) => report['id'] == created['id'],
    );

    return Report.fromJson(stored);
  }

  @override
  Future<ReportBundle> fetchReports(
    String missingId, {
    double minSimilarity = 0,
    bool includeLow = true,
    DateTime? until,
  }) async {
    await _delay(latency);

    final record = _backend.findCase(missingId);
    if (record == null) throw _notFound();

    final enriched = _enrich(_backend.reportsFor(missingId), missingId);

    final visible = enriched.where((report) {
      final observedAt = DateTime.parse(report['observed_at'] as String);
      if (until != null && observedAt.isAfter(until)) return false;

      final grade = SimilarityGrade.fromJson(report['grade']);
      if (!includeLow && !grade.countsTowardPath) return false;

      final similarity = (report['similarity'] as num?)?.toDouble() ?? 0;
      return similarity >= minSimilarity;
    }).toList();

    // 타임라인은 최신이 위. 경로는 시간순. 반대인 것은 의도된 것이다.
    final timeline = [...visible]
      ..sort(
        (a, b) => DateTime.parse(
          b['observed_at'] as String,
        ).compareTo(DateTime.parse(a['observed_at'] as String)),
      );

    final origin = {
      'lat': record['last_lat'],
      'lng': record['last_lng'],
      'address': record['last_address'],
      'at': record['missing_at'],
    };

    final onPath = visible.where((r) => r['route_index'] != null).toList()
      ..sort(
        (a, b) => (a['route_index'] as int).compareTo(b['route_index'] as int),
      );

    final path = <Map<String, dynamic>>[
      {...origin, 'index': 0, 'origin': true},
      for (final report in onPath)
        {
          'lat': report['lat'],
          'lng': report['lng'],
          'at': report['observed_at'],
          'index': report['route_index'],
        },
    ];

    final ticks = onPath
        .map((report) => report['observed_at'] as String)
        .toList(growable: false);

    return ReportBundle.fromJson({
      'missing_id': missingId,
      'count': visible.length,
      'hidden_count': enriched.length - visible.length,
      'origin': origin,
      'reports': timeline,
      'path': path,
      'time_range': {
        'from': record['missing_at'],
        'to': ticks.isEmpty ? record['missing_at'] : ticks.last,
        'ticks': ticks,
      },
    });
  }

  /// 저장된 제보에 서버가 계산해 주는 값들을 채운다.
  ///
  /// `route_index`는 40% 이상 제보를 목격 시각 순으로 줄 세워 1부터 매긴다.
  /// `gap_minutes`·`bearing`·`distance_from_prev_km`는 경로상 바로 앞 지점 기준이다.
  List<Map<String, dynamic>> _enrich(
    List<Map<String, dynamic>> reports,
    String missingId,
  ) {
    final record = _backend.findCase(missingId)!;
    final byTime = [...reports]
      ..sort(
        (a, b) => DateTime.parse(
          a['observed_at'] as String,
        ).compareTo(DateTime.parse(b['observed_at'] as String)),
      );

    var routeIndex = 0;
    var previousLat = record['last_lat'] as double;
    var previousLng = record['last_lng'] as double;
    var previousAt = DateTime.parse(record['missing_at'] as String);

    return byTime.map((report) {
      final grade = SimilarityGrade.fromJson(report['grade']);
      if (!grade.countsTowardPath) {
        return {...report, 'route_index': null};
      }

      routeIndex += 1;
      final lat = report['lat'] as double;
      final lng = report['lng'] as double;
      final observedAt = DateTime.parse(report['observed_at'] as String);
      final distance = MockBackend.haversineKm(
        previousLat,
        previousLng,
        lat,
        lng,
      );

      final enriched = {
        ...report,
        'route_index': routeIndex,
        'gap_minutes': observedAt.difference(previousAt).inMinutes,
        'bearing': _bearing(previousLat, previousLng, lat, lng),
        'distance_from_prev_km': double.parse(distance.toStringAsFixed(2)),
      };

      previousLat = lat;
      previousLng = lng;
      previousAt = observedAt;

      return enriched;
    }).toList();
  }

  /// 8방위 문자열. 치매 부모를 찾는 보호자가 방향을 판단할 때 쓴다.
  String _bearing(double lat1, double lng1, double lat2, double lng2) {
    const names = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    double toRadians(double degrees) => degrees * math.pi / 180;

    final dLng = toRadians(lng2 - lng1);
    final y = math.sin(dLng) * math.cos(toRadians(lat2));
    final x =
        math.cos(toRadians(lat1)) * math.sin(toRadians(lat2)) -
        math.sin(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.cos(dLng);

    final degrees = (math.atan2(y, x) * 180 / math.pi + 360) % 360;
    return names[((degrees + 22.5) ~/ 45) % 8];
  }

  ApiException _notFound() {
    return const ApiException(
      '이미 종료되었거나 없는 사건이에요.',
      statusCode: 404,
      code: ApiErrorCode.notFound,
    );
  }

  Future<void> _delay(Duration duration) {
    return duration == Duration.zero
        ? Future<void>.value()
        : Future<void>.delayed(duration);
  }
}
