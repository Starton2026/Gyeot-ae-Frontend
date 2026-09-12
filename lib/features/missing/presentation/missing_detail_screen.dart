import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/elapsed_time.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/map_preview_card.dart';
import '../data/missing_case.dart';
import 'missing_detail_providers.dart';
import 'widgets/detail_fact_list.dart';
import 'widgets/detail_name_line.dart';
import 'widgets/detail_photo_carousel.dart';
import 'widgets/detail_report_cta.dart';
import 'widgets/detail_status_line.dart';
import 'widgets/detail_top_bar.dart';
import 'widgets/report_timeline.dart';

/// 실종자 상세(S3). 로그인 없이 볼 수 있다.
///
/// 사진 → 상태·기본 정보 → 이동 경로 → 제보 타임라인 순으로 읽힌다. 제보
/// 버튼은 하단에 고정되고, 하단 네비게이션은 숨긴다(F-3.7).
class MissingDetailScreen extends ConsumerStatefulWidget {
  const MissingDetailScreen({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<MissingDetailScreen> createState() =>
      _MissingDetailScreenState();
}

class _MissingDetailScreenState extends ConsumerState<MissingDetailScreen> {
  /// 사진 높이. 상단바 배경이 차오르는 지점의 기준이 된다.
  static const double _heroHeight = 246;

  /// 배경이 다 차오르기까지 걸리는 스크롤 거리.
  static const double _backgroundFade = 60;

  /// 제목이 다 나타나기까지 걸리는 스크롤 거리.
  static const double _titleFade = 40;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0);
  final GlobalKey _stageKey = GlobalKey();
  final GlobalKey _nameKey = GlobalKey();

  /// 상단바가 이름을 다 이어받는 스크롤 위치. 이름 줄을 재서 정한다.
  double? _titleRevealEnd;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  /// 이름 줄의 위치를 재서 제목 전환 지점을 정한다(F-3.6).
  ///
  /// 값을 박아두지 않는 이유는 글자 크기 설정과 이름 길이에 따라 줄 위치가
  /// 달라지기 때문이다. 한 번만 재면 된다.
  void _measureNamePosition() {
    if (_titleRevealEnd != null) return;

    final nameBox = _nameKey.currentContext?.findRenderObject() as RenderBox?;
    final stageBox = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (nameBox == null || stageBox == null || !nameBox.hasSize) return;

    final top = nameBox.localToGlobal(Offset.zero, ancestor: stageBox).dy;
    final bottom = top + nameBox.size.height + _scrollController.offset;

    setState(() => _titleRevealEnd = bottom - DetailTopBar.height);
  }

  /// 사진이 상단바 밑으로 다 올라오면 1이 된다.
  double _backgroundProgress(double offset) {
    const end = _heroHeight - DetailTopBar.height;
    const start = end - _backgroundFade;

    return ((offset - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// 본문의 이름이 가려지는 동안 0에서 1로 간다.
  double _titleProgress(double offset) {
    final end = _titleRevealEnd;
    if (end == null) return 0;

    final start = end - _titleFade;

    return ((offset - start) / (end - start)).clamp(0.0, 1.0);
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    // 공유 링크로 들어와 돌아갈 스택이 없다. 홈으로 보낸다(5.5).
    context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(missingDetailProvider(widget.caseId));
    final data = detail.value;

    if (data != null && _titleRevealEnd == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _measureNamePosition(),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          key: _stageKey,
          children: [
            detail.when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => ErrorView(
                message: error is ApiException
                    ? error.message
                    : '사건을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                onRetry: () =>
                    ref.invalidate(missingDetailProvider(widget.caseId)),
              ),
              data: (detail) => _DetailBody(
                detail: detail,
                heroHeight: _heroHeight,
                scrollController: _scrollController,
                nameKey: _nameKey,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollOffset,
                builder: (context, offset, child) => DetailTopBar(
                  backgroundProgress: _backgroundProgress(offset),
                  titleProgress: _titleProgress(offset),
                  title: data == null ? '' : '${data.name} · ${data.age}세',
                  elapsedLabel: data == null || data.status != CaseStatus.active
                      ? null
                      : ElapsedTime.fromMinutes(data.elapsedMinutes).label,
                  isExternalEntry: !context.canPop(),
                  onLeading: _goBack,
                  // TODO(공유): 공유 기능이 붙으면 연결한다.
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: data == null
          ? null
          // TODO(S4): 제보창이 생기면 onTap을 연결한다.
          : DetailReportCta(label: data.category.witnessCtaLabel),
    );
  }
}

/// 본문. 사진과 본문이 **한 스크롤 안에** 있어야 상단바가 사진을 덮으며 올라온다.
class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.detail,
    required this.heroHeight,
    required this.scrollController,
    required this.nameKey,
  });

  final MissingCaseDetail detail;
  final double heroHeight;
  final ScrollController scrollController;

  /// 상단바가 제목을 이어받는 지점을 재려고 화면이 넘겨주는 키.
  final GlobalKey nameKey;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailPhotoCarousel(photos: detail.photos, height: heroHeight),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailStatusLine(
                  status: detail.status,
                  elapsedMinutes: detail.elapsedMinutes,
                ),
                const SizedBox(height: 11),
                DetailNameLine(
                  key: nameKey,
                  name: detail.name,
                  ageGenderLabel: formatAgeGender(
                    detail.age,
                    detail.gender,
                    separator: ' · ',
                  ),
                ),
                const SizedBox(height: 16),
                DetailFactList(detail: detail),
                const SizedBox(height: 6),
                _ReportsSection(caseId: detail.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 이동 경로 미니 지도(F-3.4)와 제보 타임라인(F-3.5).
///
/// 사건 정보와 따로 불러오기 때문에, 제보가 늦게 와도 사진과 인상착의는 먼저
/// 읽을 수 있다.
class _ReportsSection extends ConsumerWidget {
  const _ReportsSection({required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(caseReportsProvider(caseId));
    final highOnly = ref.watch(timelineHighOnlyProvider);

    return reports.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorView(
          message: error is ApiException
              ? error.message
              : '제보를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(caseReportsProvider(caseId)),
        ),
      ),
      data: (bundle) {
        final view = TimelineView.of(bundle, highOnly: highOnly);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO(S5): 지도 화면이 생기면 사건 선택 모드로 연결한다.
            MapPreviewCard(
              height: 126,
              label: bundle.count == 0
                  ? '마지막 목격 위치'
                  : '제보 ${bundle.count}건으로 복원한 이동 경로',
            ),
            const SizedBox(height: 26),
            ReportTimeline(
              view: view,
              totalCount: bundle.count,
              origin: bundle.origin,
              highOnly: highOnly,
              onHighOnlyChanged: ref
                  .read(timelineHighOnlyProvider.notifier)
                  .set,
            ),
          ],
        );
      },
    );
  }
}
