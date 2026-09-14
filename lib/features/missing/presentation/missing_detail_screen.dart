import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/elapsed_time.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/share/case_sharer.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/resolve_case_dialog.dart';
import '../../report/data/report.dart';
import '../data/missing_case.dart';
import '../data/missing_repository.dart';
import 'case_guardian_actions.dart';
import 'case_share_card.dart';
import 'widgets/detail_body.dart';
import 'widgets/detail_guardian_bar.dart';
import 'widgets/detail_report_cta.dart';
import 'widgets/detail_top_bar.dart';

/// 실종자 상세(S3). 로그인 없이 볼 수 있다.
///
/// 사진 → 상태·기본 정보 → 이동 경로 → 제보 타임라인 순으로 읽힌다. 제보
/// 버튼은 하단에 고정되고, 하단 네비게이션은 숨긴다(F-3.7).
class MissingDetailScreen extends ConsumerStatefulWidget {
  const MissingDetailScreen({
    required this.caseId,
    this.fromLink = false,
    super.key,
  });

  final String caseId;

  /// 앱 밖 링크(앱 링크·카카오톡 공유)로 열었다. 뒤로 대신 작은 심볼을 두고
  /// 누르면 홈으로 간다(5.5 외부 유입 상세).
  final bool fromLink;

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
    // 링크로 온 사람에게 뒤는 앱에 들어오기 전의 무언가다. 홈을 보여준다.
    if (!widget.fromLink && context.canPop()) {
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
              data: (detail) => DetailBody(
                detail: detail,
                heroHeight: _heroHeight,
                scrollController: _scrollController,
                nameKey: _nameKey,
                onToggleConfirmed: detail.isGuardian ? _toggleConfirmed : null,
                onToggleHidden: detail.isGuardian ? _toggleHidden : null,
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
                  isExternalEntry: widget.fromLink || !context.canPop(),
                  onLeading: _goBack,
                  onShare: data == null ? null : () => unawaited(_share(data)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: switch (data) {
        null => null,
        // 끝난 사건에서는 보호자가 이 화면에서 할 일이 없다.
        MissingCaseDetail(isGuardian: true, status: CaseStatus.resolved) =>
          null,
        MissingCaseDetail(isGuardian: true) => DetailGuardianBar(
          busy: _busy,
          onEdit: () => unawaited(_edit()),
          onAddPhotos: () => unawaited(_addPhotos(data)),
          onResolve: () => unawaited(_resolve(data)),
        ),
        _ => DetailReportCta(
          label: data.category.witnessCtaLabel,
          onTap: () => context.push(AppRoute.report(widget.caseId)),
        ),
      },
    );
  }

  /// 카카오톡으로 보낸다. 받은 사람이 누르면 이 상세가 열린다.
  Future<void> _share(MissingCaseDetail detail) async {
    final result = await ref
        .read(caseSharerProvider)
        .share(caseShareCardFor(detail));
    final message = shareResultMessage(result);
    if (message != null && mounted) _say(message);
  }

  // ── 보호자 동작(F-3.8) ─────────────────────────────────────

  /// 사진을 올리거나 발견 완료를 보내는 중. 두 번 눌리지 않게 잠근다.
  bool _busy = false;

  CaseGuardianActions get _actions => ref.read(caseGuardianActionsProvider);

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 보호자 동작 하나를 잠근 채 돌리고, 실패하면 이유를 알린다.
  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await action();
    } on ApiException catch (error) {
      if (mounted) _say(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final saved = await context.push<bool>(AppRoute.caseEdit(widget.caseId));
    if (saved == true && mounted) _say('정보를 고쳤어요');
  }

  Future<void> _addPhotos(MissingCaseDetail detail) {
    if (detail.photos.length >= CaseGuardianActions.maxCasePhotos) {
      _say('사진은 ${CaseGuardianActions.maxCasePhotos}장까지 올릴 수 있어요');
      return Future.value();
    }

    return _guarded(() async {
      final result = await _actions.addPhotos(
        detail.id,
        currentPhotoCount: detail.photos.length,
      );
      if (result == null || !mounted) return;

      // 사진을 더한 보람이 보여야 한다. 몇 건을 다시 봤는지 적는다.
      _say(
        result.reanalyzedReports == 0
            ? '사진을 더했어요'
            : '사진을 더했어요. 제보 ${result.reanalyzedReports}건을 다시 분석했어요',
      );
    });
  }

  Future<void> _resolve(MissingCaseDetail detail) async {
    if (!await ResolveCaseDialog.show(context, name: detail.name)) return;

    await _guarded(() async {
      await _actions.resolve(detail.id);
      if (mounted) _say('발견 완료로 바꿨어요. 제보해 주신 분들께 결과를 알려드렸어요');
    });
  }

  void _toggleConfirmed(Report report) {
    unawaited(
      _guarded(
        () => _actions.setReportConfirmed(
          widget.caseId,
          report.id,
          confirmed: !report.confirmed,
        ),
      ),
    );
  }

  void _toggleHidden(Report report) {
    final hide = report.status != ReportStatus.hidden;

    unawaited(
      _guarded(() async {
        await _actions.setReportHidden(widget.caseId, report.id, hidden: hide);
        // 숨기기는 경로 번호를 바꾼다. 무엇이 달라졌는지 한 줄 남긴다.
        if (mounted) _say(hide ? '숨겼어요. 경로와 지도에서 빠져요' : '다시 보이게 했어요');
      }),
    );
  }
}

