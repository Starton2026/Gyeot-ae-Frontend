import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/my/data/my_report.dart';
import 'package:gyeotae/features/my/data/my_repository.dart';
import 'package:gyeotae/features/report/data/report.dart';

/// 내 제보 이력을 정해두고 돌려준다.
class FakeMyRepository implements MyRepository {
  FakeMyRepository({MyReportList? reports, MissingCaseList? cases, this.error})
    : reports = reports ?? const MyReportList.empty(),
      cases = cases ?? const MissingCaseList.empty();

  final MyReportList reports;
  final MissingCaseList cases;
  final Object? error;

  int calls = 0;

  /// 발견 완료로 바꾼 사건 id.
  final List<String> resolved = [];

  @override
  Future<MyReportList> fetchMyReports() async {
    calls += 1;

    final failure = error;
    if (failure != null) throw failure;

    return reports;
  }

  @override
  Future<MissingCaseList> fetchMyCases() async => cases;

  @override
  Future<int> resolveCase(String caseId) async {
    resolved.add(caseId);

    return 3;
  }
}

/// 사건 하나. 필요한 값만 이름으로 바꿔 쓴다.
MissingCaseSummary fakeMyCase({
  String id = 'm_1',
  String name = '김하준',
  int age = 7,
  CaseStatus status = CaseStatus.active,
  int elapsedMinutes = 185,
  int reportCount = 6,
  DateTime? resolvedAt,
}) {
  return MissingCaseSummary(
    id: id,
    name: name,
    age: age,
    gender: Gender.male,
    category: MissingCategory.child,
    description: '노란 후드티',
    lastLat: 37.47,
    lastLng: 126.75,
    missingAt: DateTime(2026, 9, 13, 17),
    elapsedMinutes: elapsedMinutes,
    status: status,
    resolvedAt: resolvedAt,
    reportCount: reportCount,
    urgencyLevel: UrgencyLevel.high,
  );
}

/// 제보 한 건. 필요한 값만 이름으로 바꿔 쓴다.
MyReport fakeMyReport({
  String id = 'r_1',
  String? missingId = 'm_1',
  String missingName = '김하준',
  CaseStatus missingStatus = CaseStatus.active,
  double? similarity = 82.1,
  SimilarityGrade grade = SimilarityGrade.high,
  DateTime? observedAt,
  bool contributedToPath = true,
}) {
  return MyReport(
    id: id,
    missingId: missingId,
    missingName: missingName,
    missingStatus: missingStatus,
    similarity: similarity,
    grade: grade,
    observedAt: observedAt ?? DateTime(2026, 9, 13, 17, 12),
    contributedToPath: contributedToPath,
  );
}
