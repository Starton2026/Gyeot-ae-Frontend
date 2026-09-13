import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../../core/location/location_source.dart';
import '../../../core/media/photo_picker.dart';
import '../data/analysis.dart';
import '../data/report.dart';
import '../data/report_repository.dart';

/// 목격 위치가 어디서 온 값인가.
///
/// **어디서 왔는지가 그 값을 믿을 수 있는지를 정한다.** 사진에 박힌 좌표는
/// 그 사진을 찍은 자리고, 기기 위치는 지금 내가 선 자리다. 앨범에서 고른
/// 사진이라면 둘이 다를 수 있다.
enum ReportLocationSource {
  /// 사진에 박힌 촬영 좌표.
  photo,

  /// 기기가 지금 알려준 좌표.
  device,

  /// 못 받았다. 위치 없이 보낸다.
  none,
}

/// 목격 시각이 어디서 온 값인가.
enum ReportTimeSource {
  /// 사진을 올린 시각. 아무것도 모를 때의 기본값.
  now,

  /// 사진에 박힌 촬영 시각(F-4.4).
  photo,

  /// 사용자가 직접 고쳤다.
  manual,
}

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
    this.photoSource,
    this.fix,
    this.fixSource = ReportLocationSource.none,
    this.timeSource = ReportTimeSource.now,
    this.placeName = '',
    this.analysis = const AsyncData(null),
    this.submission = const AsyncData(null),
  });

  /// 고른 사진의 로컬 경로. 아직 안 골랐으면 null.
  final String? photoPath;

  /// 그 사진을 어디서 가져왔는지. 카메라면 "지금 이 자리"가 참이다.
  final PhotoSource? photoSource;

  /// 목격 좌표. **null이면 위치 없이 보낸다.**
  ///
  /// 지어내서 채우지 않는다. 아무도 보지 않은 자리에 점이 찍히면 보호자가
  /// 엉뚱한 곳을 찾는다(CLAUDE.md — 위치 권한 거부는 정상 경로).
  final LocationFix? fix;

  final ReportLocationSource fixSource;

  /// **목격 시각.** 경로 정렬 기준이다(설계 결정 5번).
  final DateTime observedAt;

  final ReportTimeSource timeSource;

  /// "만수주공 앞 버스정류장". 비어 있으면 보내지 않는다.
  final String placeName;

  /// 분석 결과. 값이 null이면 아직 분석 전이다.
  final AsyncValue<AnalysisResult?> analysis;

  /// 확정된 제보. 값이 null이면 아직 보내기 전이다.
  final AsyncValue<Report?> submission;

  bool get hasPhoto => photoPath != null;

  bool get hasLocation => fix != null;

  /// **앨범 사진인데 좌표를 사진에서 못 얻었다.**
  ///
  /// 지금 내가 선 자리를 붙여뒀는데, 그 사진은 어제 다른 동네에서 찍은 것일
  /// 수 있다. 사용자에게 한 번 물어봐야 하는 유일한 경우다.
  bool get needsLocationCheck =>
      photoSource == PhotoSource.gallery &&
      fixSource == ReportLocationSource.device;

  /// 제보에 실릴 위치를 사람 말로. 제보창·분석 시트가 같은 말을 써야 한다.
  String locationName(String deviceLabel) => switch (fixSource) {
    ReportLocationSource.photo => '사진에 찍힌 위치',
    ReportLocationSource.device => deviceLabel,
    ReportLocationSource.none => '위치 없음',
  };

  AnalysisResult? get analysisResult => analysis.value;

  /// 분석을 마쳤다. 이때부터 제보 버튼이 살아난다(F-4.6).
  bool get isAnalyzed => analysisResult != null;

  bool get isAnalyzing => analysis.isLoading;
  bool get isSubmitting => submission.isLoading;

  bool get canAnalyze => hasPhoto && !isAnalyzing;
  bool get canSubmit => isAnalyzed && !isSubmitting;

  /// 나가면 사라지는 것이 있다. 이탈 방지 확인을 띄울지 정한다(F-4.7).
  bool get hasWorkInProgress => hasPhoto;

  /// [fix]와 [fixSource]는 **함께 움직인다.** 좌표만 바꾸고 출처를 안 바꾸면
  /// 어디서 온 값인지 모르는 좌표가 남는다. 그래서 출처를 넘길 때만 좌표도
  /// 갈아낀다.
  ReportDraft copyWith({
    String? photoPath,
    PhotoSource? photoSource,
    LocationFix? fix,
    ReportLocationSource? fixSource,
    DateTime? observedAt,
    ReportTimeSource? timeSource,
    String? placeName,
    AsyncValue<AnalysisResult?>? analysis,
    AsyncValue<Report?>? submission,
  }) {
    return ReportDraft(
      photoPath: photoPath ?? this.photoPath,
      photoSource: photoSource ?? this.photoSource,
      fix: fixSource == null ? this.fix : fix,
      fixSource: fixSource ?? this.fixSource,
      observedAt: observedAt ?? this.observedAt,
      timeSource: timeSource ?? this.timeSource,
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
  ReportDraft build() {
    // 위치는 화면을 연 뒤에 도착하는 일이 흔하다. 그때 갈아끼우되, 사진에서
    // 얻은 좌표는 덮지 않는다.
    ref.listen(currentLocationProvider, (previous, next) => _useDevice(next));

    final fix = ref.read(currentLocationProvider).fix;

    return ReportDraft(
      observedAt: DateTime.now(),
      fix: fix,
      fixSource: fix == null
          ? ReportLocationSource.none
          : ReportLocationSource.device,
    );
  }

  void _useDevice(AppLocation location) {
    final fix = location.fix;
    if (fix == null) return;

    // 사진에 박힌 좌표가 더 사실에 가깝다. 기기 위치로 덮지 않는다.
    if (state.fixSource == ReportLocationSource.photo) return;

    state = state.copyWith(
      fix: fix,
      fixSource: ReportLocationSource.device,
    );
  }

  /// 카메라나 앨범에서 사진을 고른다(F-4.2).
  ///
  /// 취소하거나 권한이 없으면 아무 일도 일어나지 않는다. 사진에 촬영 시각과
  /// 좌표가 박혀 있으면 그것을 먼저 쓴다(F-4.3·F-4.4).
  Future<void> pickPhoto(PhotoSource source) async {
    final picked = await ref.read(photoPickerProvider).pick(source);
    if (picked == null || !ref.mounted) return;

    final photoFix = picked.fix;
    final deviceFix = ref.read(currentLocationProvider).fix;
    final taken = picked.takenAt;

    state = state.copyWith(
      photoPath: picked.path,
      photoSource: source,
      // 사진이 바뀌면 앞선 분석은 다른 사진의 결과다. 같이 버린다.
      analysis: const AsyncData(null),
      fix: photoFix ?? deviceFix,
      fixSource: switch ((photoFix, deviceFix)) {
        (final LocationFix _, _) => ReportLocationSource.photo,
        (null, final LocationFix _) => ReportLocationSource.device,
        _ => ReportLocationSource.none,
      },
      observedAt: taken ?? state.observedAt,
      timeSource: taken == null ? state.timeSource : ReportTimeSource.photo,
    );
  }

  /// 위치를 다시 물어본다. 받으면 [_useDevice]가 갈아낀다.
  Future<void> retryLocation() {
    return ref.read(currentLocationProvider.notifier).locate();
  }

  /// 목격 시각을 고친다(F-4.4). 사진첩에서 나중에 올릴 때 쓴다.
  void setObservedAt(DateTime at) {
    state = state.copyWith(
      observedAt: at,
      timeSource: ReportTimeSource.manual,
    );
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
  /// 좌표가 없으면 **비워서** 보낸다. 지어낸 좌표보다 빈 좌표가 낫다.
  ///
  /// 실패 사유는 `state.submission`에 남는다. 분석이 만료됐으면
  /// `ApiErrorCode.analysisExpired`다.
  Future<Report?> submit() async {
    final analysis = state.analysisResult;
    if (analysis == null || state.isSubmitting) return null;

    final fix = state.fix;
    final placeName = state.placeName;

    state = state.copyWith(submission: const AsyncLoading());

    final result = await AsyncValue.guard(
      () => ref.read(reportRepositoryProvider).submit(
        analysisId: analysis.analysisId,
        lat: fix?.lat,
        lng: fix?.lng,
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
