import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../missing/data/missing_case.dart';
import '../../missing/data/missing_repository.dart';
import '../data/report_repository.dart';
import 'report_draft_providers.dart';
import 'widgets/report_analysis_sheet.dart';
import 'widgets/report_analysis_slot.dart';
import 'widgets/report_auto_facts.dart';
import 'widgets/report_exit_dialog.dart';
import 'widgets/report_photo_field.dart';
import 'widgets/report_place_sheet.dart';
import 'widgets/report_submit_bar.dart';
import 'widgets/report_target_header.dart';

/// 제보창(S4). 로그인 없이 쓴다(설계 결정 1번).
///
/// 시민이 채우는 칸은 사진 한 장뿐이고, 시각과 위치는 자동으로 담긴다.
/// 하단 네비게이션을 숨겨서(F-4.7) 쓰다 말고 다른 탭으로 새지 않게 한다.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({required this.caseId, super.key});

  final String caseId;

  /// 뒤로 갈 곳. 공유 링크로 바로 들어왔으면 사건 상세로 보낸다.
  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoute.missingDetail(caseId));
  }

  /// 닫기·취소·안드로이드 뒤로가기가 모두 지나가는 자리(F-4.7).
  Future<void> _close(BuildContext context, WidgetRef ref) async {
    if (ref.read(reportDraftProvider(caseId)).hasWorkInProgress) {
      final leave = await confirmLeaveReport(context);
      if (!leave || !context.mounted) return;
    }

    _leave(context);
  }

  /// 목격 시각을 고친다(F-4.4).
  ///
  /// 날짜부터 묻는 이유는 사진첩에서 어제 것을 올리는 경우가 있어서다.
  /// 앞으로의 시각은 목격 시각이 될 수 없어 지금으로 당긴다.
  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(reportDraftProvider(caseId));
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: draft.observedAt,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
      helpText: '목격한 날짜',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(draft.observedAt),
      helpText: '목격한 시각',
    );
    if (time == null) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final observedAt = picked.isAfter(DateTime.now())
        ? DateTime.now()
        : picked;

    ref.read(reportDraftProvider(caseId).notifier).setObservedAt(observedAt);
  }

  /// 사진 분석(F-4.5). 결과는 바텀시트로 보여준다(S4-1).
  ///
  /// 시트를 **먼저** 연다. 분석은 몇 초 걸리는데 그동안 화면이 멈춘 것처럼
  /// 보이면 사용자가 버튼을 다시 누른다.
  void _analyze(BuildContext context, WidgetRef ref) {
    unawaited(ref.read(reportDraftProvider(caseId).notifier).analyze());
    unawaited(showAnalysisSheet(context, caseId: caseId));
  }

  /// 장소 이름을 적는다(F-4.3). 좌표는 건드리지 않는다.
  Future<void> _editPlace(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(reportDraftProvider(caseId));
    final name = await showReportPlaceSheet(context, initial: draft.placeName);
    if (name == null) return;

    ref.read(reportDraftProvider(caseId).notifier).setPlaceName(name);
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    // 보내고 나면 이 화면은 사라진다. 메신저를 미리 잡아둔다.
    final messenger = ScaffoldMessenger.of(context);
    final report = await ref
        .read(reportDraftProvider(caseId).notifier)
        .submit();

    if (!context.mounted) return;

    if (report == null) {
      final error = ref.read(reportDraftProvider(caseId)).submission.error;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : '제보를 보내지 못했어요. 잠시 후 다시 시도해 주세요.',
          ),
        ),
      );
      return;
    }

    // 방금 보낸 제보가 상세 타임라인과 지도에 바로 보이게 다시 받아온다.
    ref.invalidate(caseReportsProvider(caseId));
    ref.invalidate(missingDetailProvider(caseId));

    // 완료 화면으로 갈아탄다. 뒤로 눌러 쓰다 만 제보창으로 돌아가면
    // 이미 보낸 것을 또 보내게 된다.
    context.pushReplacement(AppRoute.reportDone(caseId), extra: report);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(missingDetailProvider(caseId));
    final draft = ref.watch(reportDraftProvider(caseId));

    return PopScope(
      canPop: !draft.hasWorkInProgress,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final leave = await confirmLeaveReport(context);
        if (!leave || !context.mounted) return;

        _leave(context);
      },
      child: Scaffold(
        appBar: AppTopBar.modal(
          '제보하기',
          onClose: () => _close(context, ref),
        ),
        body: detail.when(
          loading: () => const LoadingView(),
          error: (error, stackTrace) => ErrorView(
            message: error is ApiException
                ? error.message
                : '사건을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
            onRetry: () => ref.invalidate(missingDetailProvider(caseId)),
          ),
          data: (detail) => _ReportForm(
            detail: detail,
            draft: draft,
            deviceLabel: ref.watch(currentLocationProvider).label,
            onPickPhoto: ref
                .read(reportDraftProvider(caseId).notifier)
                .pickPhoto,
            onEditPlace: () => _editPlace(context, ref),
            onRetryLocation: ref
                .read(reportDraftProvider(caseId).notifier)
                .retryLocation,
            onEditTime: () => _editTime(context, ref),
            onAnalyze: () => _analyze(context, ref),
          ),
        ),
        bottomNavigationBar: detail.hasValue
            ? ReportSubmitBar(
                canSubmit: draft.canSubmit,
                submitting: draft.isSubmitting,
                onCancel: () => _close(context, ref),
                onSubmit: () => _submit(context, ref),
              )
            : null,
      ),
    );
  }
}

/// 제보창 본문. 읽는 순서가 곧 채우는 순서다.
///
/// 누구를 제보하는지 → 사진 → 자동으로 담긴 것 → 분석. 사진을 올려야 분석이
/// 되고, 분석해야 제보가 된다는 순서가 위에서 아래로 그대로 보인다.
class _ReportForm extends StatelessWidget {
  const _ReportForm({
    required this.detail,
    required this.draft,
    required this.deviceLabel,
    required this.onPickPhoto,
    required this.onEditPlace,
    required this.onRetryLocation,
    required this.onEditTime,
    required this.onAnalyze,
  });

  final MissingCaseDetail detail;
  final ReportDraft draft;

  /// 기기 위치에 붙일 이름. "현재 위치".
  final String deviceLabel;

  final void Function(PhotoSource source) onPickPhoto;
  final VoidCallback onEditPlace;
  final VoidCallback onRetryLocation;
  final VoidCallback onEditTime;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
      children: [
        ReportTargetHeader(
          name: detail.name,
          ageGenderLabel: detail.ageGenderLabel,
          description: detail.description,
          thumbnail: detail.photos.firstOrNull,
        ),
        const SizedBox(height: 13),
        ReportPhotoField(photoPath: draft.photoPath, onPick: onPickPhoto),
        const SizedBox(height: 13),
        ReportAutoFacts(
          draft: draft,
          deviceLabel: deviceLabel,
          onEditPlace: onEditPlace,
          onRetryLocation: onRetryLocation,
          onEditTime: onEditTime,
        ),
        const SizedBox(height: 13),
        ReportAnalysisSlot(
          analysis: draft.analysis,
          hasPhoto: draft.hasPhoto,
          onAnalyze: onAnalyze,
        ),
      ],
    );
  }
}
