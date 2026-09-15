import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/json.dart';
import '../../../core/network/dio_provider.dart';
import '../../missing/data/missing_case.dart';
import 'my_report.dart';

/// MY 화면(S8)이 보는 데이터.
abstract interface class MyRepository {
  /// 내 제보 이력. API 명세서 18) `GET /me/reports`.
  ///
  /// **로그인하지 않아도 부른다.** 토큰이 있으면 계정 기준, 없으면 기기
  /// 기준(`X-Device-Hash`)으로 서버가 알아서 고른다. 게스트도 자기가 무엇을
  /// 제보했는지는 볼 수 있어야 한다(F-8.2).
  Future<MyReportList> fetchMyReports();

  /// 내가 보호자인 사건 목록. `GET /me/missing`.
  ///
  /// 진행 중이 먼저 오고, 각각 최근 실종 순이다. 항목은 실종자 목록과 같은
  /// 모양이라 [MissingCaseSummary]를 그대로 쓴다.
  ///
  /// 로그인해야 부를 수 있다. 로그아웃 상태에서는 부르지 않는다.
  Future<MissingCaseList> fetchMyCases();

  /// 발견 완료로 바꾼다. `POST /missing/{id}/resolve`. **보호자만.**
  ///
  /// 사건을 지우지 않는다(설계 결정 7번). 상태만 바뀌고 목록에는 남는다.
  /// 돌려주는 값은 결과 알림이 나갈 제보자 수다.
  Future<int> resolveCase(String caseId);
}

class HttpMyRepository implements MyRepository {
  const HttpMyRepository(this._dio);

  final Dio _dio;

  @override
  Future<MyReportList> fetchMyReports() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me/reports');

      return MyReportList.fromJson(response.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<MissingCaseList> fetchMyCases() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/me/missing');

      return MissingCaseList.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<int> resolveCase(String caseId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/missing/$caseId/resolve',
      );

      return jsonInt(response.data?['notified_reporters']);
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}

final myRepositoryProvider = Provider<MyRepository>((ref) {
  return HttpMyRepository(ref.watch(dioProvider));
});
