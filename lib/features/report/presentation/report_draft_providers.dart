import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../../core/media/photo_picker.dart';
import '../data/analysis.dart';
import '../data/report.dart';
import '../data/report_repository.dart';

/// 제보창(S4)이 쥐고 있는 것 전부.
///
/// 시민이 직접 채우는 칸은 **사진 한 장뿐이다**(기능정의서 S4). 시각과 위치는
/// 자동으로 담기고, 고치는 것은 원할 때만이다.
///
/// 분석과 제보를 [AsyncValue]로 들고 있는 이유는, 둘 다 "아직 안 함 / 하는 중 /
/// 실패 / 끝남" 네 상태를 갖기 때문이다. 플래그를 따로 두면 분석 중에 실패
/// 표시가 남아 있는 조합이 생긴다.
class ReportDraft {
  const ReportDraft({
    required this.observedAt,
    this.photoPath,
    this.placeName = '',
    this.observedAtEdited = false,
    this.analysis = const AsyncData(null),
    this.submission = const AsyncData(null),
  });

  /// 고른 사진의 로컬 경로. 아직 안 골랐으면 null.
  final String? photoPath;

  /// **목격 시각.** 경로 정렬 기준이다(설계 결정 5번).
  final DateTime observedAt;

  /// 사용자가 시각을 직접 고쳤다. 자동으로 담긴 값과 구분해 적는다.
  final bool observedAtEdited;

  /// "만수주공 앞 버스정류장". 비어 있으면 보내지 않는다.
  final String placeName;

  /// 분석 결과. 값이 null이면 아직 분석 전이다.
  final AsyncValue<AnalysisResult?> analysis;

  /// 확정된 제보. 값이 null이면 아직 보내기 전이다.
  final AsyncValue<Report?> submission;

  bool get hasPhoto => photoPath != null;

  AnalysisResult? get analysisResult => analysis.value;

  /// 분석을 마쳤다. 이때부터 제보 버튼이 살아난다(F-4.6).
  bool get isAnalyzed => analysisResult != null;

  bool get isAnalyzing => analysis.isLoading;
  bool get isSubmitting => submission.isLoading;

  bool get canAnalyze => hasPhoto && !isAnalyzing;
  bool get canSubmit => isAnalyzed && !isSubmitting;

  /// 나가면 사라지는 것이 있다. 이탈 방지 확인을 띄울지 정한다(F-4.7).
  bool get hasWorkInProgress => hasPhoto;

  ReportDraft copyWith({
    String? photoPath,
    DateTime? observedAt,
    bool? observedAtEdited,
    String? placeName,
    AsyncValue<AnalysisResult?>? analysis,
    AsyncValue<Report?>? submission,
  }) {
    return ReportDraft(
      photoPath: photoPath ?? this.photoPath,
      observedAt: observedAt ?? this.observedAt,
      observedAtEdited: observedAtEdited ?? this.observedAtEdited,
      placeName: placeName ?? this.placeName,
      analysis: analysis ?? this.analysis,
      submission: submission ?? this.submission,
    );
  }
}

/// 제보창 한 건의 상태. 사건마다 따로 쥔다.
///
/// 화면을 벗어나면 버린다(`isAutoDispose`). 쓰다 만 제보가 남아 있다가 다음에
/// 들어왔을 때 되살아나면, 방금 찍지도 않은 사진이 올라간다.
class ReportDraftNotifier extends Notifier<ReportDraft> {
  ReportDraftNotifier(this.missingId);

  final String missingId;

  @override
  ReportDraft build() => ReportDraft(observedAt: DateTime.now());

  /// 카메라나 앨범에서 사진을 고른다(F-4.2).
  ///
  /// 취소하거나 권한이 없으면 아무 일도 일어나지 않는다.
  Future<void> pickPhoto(PhotoSource source) async {
    final path = await ref.read(photoPickerProvider).pick(source);
    if (path == null || !ref.mounted) return;

    // 사진이 바뀌면 앞선 분석은 다른 사진의 결과다. 같이 버린다.
    state = state.copyWith(
      photoPath: path,
      analysis: const AsyncData(null),
    );
  }

  /// 목격 시각을 고친다(F-4.4). 사진첩에서 나중에 올릴 때 쓴다.
  void setObservedAt(DateTime at) {
    state = state.copyWith(observedAt: at, observedAtEdited: true);
  }

  /// 장소 이름을 적는다(F-4.3). 빈 문자열이면 지운 것으로 본다.
  void setPlaceName(String name) {
    state = state.copyWith(placeName: name.trim());
  }

  /// 사진 분석(F-4.5). API 명세서 13) `POST /reports/analyze`.
  ///
  /// 여기서 끝내지 않는다. 결과를 보여주고 확인을 받은 뒤에야 [submit]이
  /// 이어진다(설계 결정 2번).
  Future<void> analyze() async {
    final path = state.photoPath;
    if (path == null || state.isAnalyzing) return;

    state = state.copyWith(analysis: const AsyncLoading());

    final result = await AsyncValue.guard(
      () => ref.read(reportRepositoryProvider).analyze(
        missingId: missingId,
        photoPath: path,
      ),
    );

    if (!ref.mounted) return;
    state = state.copyWith(analysis: result);
  }

  /// 제보 확정(API 명세서 14). 성공하면 확정된 제보를, 실패하면 null을 준다.
  ///
  /// 실패 사유는 `state.submission`에 남는다. 분석이 만료됐으면
  /// `ApiErrorCode.analysisExpired`다.
  Future<Report?> submit() async {
    final analysis = state.analysisResult;
    if (analysis == null || state.isSubmitting) return null;

    // 위치는 자동으로 담긴다(F-4.3). 시민에게 묻지 않는다.
    final location = ref.read(currentLocationProvider);
    final placeName = state.placeName;

    state = state.copyWith(submission: const AsyncLoading());

    final result = await AsyncValue.guard(
      () => ref.read(reportRepositoryProvider).submit(
        analysisId: analysis.analysisId,
        lat: location.lat,
        lng: location.lng,
        observedAt: state.observedAt,
        placeName: placeName.isEmpty ? null : placeName,
      ),
    );

    if (!ref.mounted) return null;
    state = state.copyWith(submission: result);

    return result.value;
  }
}

final reportDraftProvider =
    NotifierProvider.family<ReportDraftNotifier, ReportDraft, String>(
      ReportDraftNotifier.new,
      isAutoDispose: true,
    );
