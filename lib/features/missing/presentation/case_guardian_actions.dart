import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/photo_picker.dart';
import '../../home/presentation/home_providers.dart';
import '../../map/presentation/map_providers.dart';
import '../../my/presentation/my_providers.dart';
import '../../report/data/report_repository.dart';
import '../data/case_edit.dart';
import '../data/missing_repository.dart';
import 'missing_list_providers.dart';

/// 실종자 상세(S3)의 보호자 전용 동작(F-3.8 · F-3.5.13).
///
/// 부르는 것뿐 아니라 **무엇을 다시 받아야 하는지까지** 여기서 끝낸다. 화면마다
/// 따로 invalidate하면 한 곳을 빠뜨리는 순간 옛 값이 남는다 — 발견 완료했는데
/// 홈에 진행 중으로 남는 것처럼(실기기 2026-09-14).
class CaseGuardianActions {
  const CaseGuardianActions(this._ref);

  final Ref _ref;

  /// 사건 한 건에 올릴 수 있는 사진 수. 서버와 같다.
  static const int maxCasePhotos = 10;

  /// 앨범에서 사진을 골라 더한다. 고르지 않았거나 자리가 없으면 null.
  ///
  /// **카메라는 열지 않는다.** 실종된 사람은 눈앞에 없다. 서버가 기존 제보의
  /// 유사도를 전부 다시 계산해서, 경로와 타임라인도 다시 받는다.
  Future<PhotoAddResult?> addPhotos(
    String caseId, {
    required int currentPhotoCount,
  }) async {
    final room = maxCasePhotos - currentPhotoCount;
    if (room < 1) return null;

    final picked = await _ref
        .read(photoPickerProvider)
        .pickManyFromGallery(limit: room);
    if (picked.isEmpty) return null;

    final result = await _ref
        .read(missingRepositoryProvider)
        .addPhotos(caseId, picked.take(room).toList(growable: false));
    refreshCase(caseId);

    return result;
  }

  /// 제보를 숨기거나 되돌린다. 숨기면 경로 번호가 당겨져 상세 건수도 바뀐다.
  Future<void> setReportHidden(
    String caseId,
    String reportId, {
    required bool hidden,
  }) async {
    await _ref
        .read(reportRepositoryProvider)
        .updateReport(reportId, hidden: hidden);
    refreshCase(caseId, lists: false);
  }

  /// "확인함" 표시. 경로는 그대로라 제보만 다시 받는다.
  Future<void> setReportConfirmed(
    String caseId,
    String reportId, {
    required bool confirmed,
  }) async {
    await _ref
        .read(reportRepositoryProvider)
        .updateReport(reportId, confirmed: confirmed);
    _ref.invalidate(caseReportsProvider(caseId));
  }

  /// 발견 완료. 결과 알림이 갈 제보자 수를 준다.
  Future<int> resolve(String caseId) async {
    final notified = await _ref
        .read(missingRepositoryProvider)
        .resolveCase(caseId);
    refreshCase(caseId);

    return notified;
  }

  /// 이 사건을 보여주는 곳을 다시 받게 한다.
  ///
  /// [lists]가 false면 상세만 다시 받는다. 목록 카드에 드러나지 않는 변화다.
  void refreshCase(String caseId, {bool lists = true}) {
    _ref
      ..invalidate(missingDetailProvider(caseId))
      ..invalidate(caseReportsProvider(caseId));
    if (!lists) return;

    _ref
      ..invalidate(homeFeedProvider)
      ..invalidate(missingListProvider)
      ..invalidate(mapCasesProvider)
      ..invalidate(myCasesProvider)
      ..invalidate(myProfileProvider);
  }
}

final caseGuardianActionsProvider = Provider<CaseGuardianActions>((ref) {
  return CaseGuardianActions(ref);
});
