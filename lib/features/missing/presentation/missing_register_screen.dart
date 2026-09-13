import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_source.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/widgets/login_sheet.dart';
import '../../home/presentation/home_providers.dart';
import '../../map/presentation/map_providers.dart';
import '../../my/presentation/my_providers.dart';
import '../data/register_form.dart';
import 'missing_list_providers.dart';
import 'register_draft_providers.dart';
import 'widgets/register_exit_dialog.dart';
import 'widgets/register_form_view.dart';
import 'widgets/register_submit_bar.dart';

/// 실종자 등록(S7). **로그인이 필요하다.**
///
/// 로그인하지 않았으면 폼을 먼저 연 뒤 그 위에 로그인 시트를 덮는다(시안 S6).
/// 무엇을 요구하는지 뒤에 보이는 채로 로그인하고, 성공하면 시트만 걷혀 폼이
/// 그대로 이어진다(F-6.4). 로그인하지 않고 시트를 닫으면 폼도 닫는다.
///
/// 하단 네비게이션을 숨긴다. 쓰다 말고 다른 탭으로 새지 않게 한다.
class MissingRegisterScreen extends ConsumerStatefulWidget {
  const MissingRegisterScreen({super.key});

  static const Key saveDraftKey = Key('register_save_draft');

  @override
  ConsumerState<MissingRegisterScreen> createState() =>
      _MissingRegisterScreenState();
}

class _MissingRegisterScreenState extends ConsumerState<MissingRegisterScreen> {
  /// 빠진 칸으로 스크롤할 때 찾는 자리.
  final Map<RegisterField, GlobalKey> _sectionKeys = {
    for (final field in RegisterField.values)
      field: GlobalKey(debugLabel: field.name),
  };

  RegisterDraftNotifier get _notifier =>
      ref.read(registerDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  /// 로그인을 확인하고, 임시저장이 있으면 이어 쓴다.
  Future<void> _start() async {
    final user = await ref.read(authProvider.future);
    if (!mounted) return;

    if (user == null) {
      final session = await showLoginSheet(context);
      if (!mounted) return;
      if (session == null) {
        _leave();
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    if (await _notifier.restoreSaved()) {
      _say(messenger, '임시저장한 내용을 불러왔어요');
    }
  }

  /// 한 줄 알림. **떠 있던 것을 치우고** 띄운다. 스낵바는 줄을 서서, 방금
  /// 임시저장 알림이 떠 있으면 등록 완료 알림이 몇 초 뒤에야 나온다.
  void _say(ScaffoldMessengerState messenger, String text) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoute.home);
  }

  /// 닫기·안드로이드 뒤로가기가 모두 지나가는 자리.
  Future<void> _close() async {
    if (!ref.read(registerDraftProvider).form.hasInput) {
      _leave();
      return;
    }

    final choice = await confirmLeaveRegister(context);
    if (!mounted) return;

    switch (choice) {
      case RegisterExitChoice.keep:
        return;
      case RegisterExitChoice.save:
        await _notifier.saveDraft();
        if (mounted) _leave();
      case RegisterExitChoice.leave:
        _leave();
    }
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    await _notifier.saveDraft();

    _say(messenger, '임시저장했어요. 다음에 이어서 쓸 수 있어요');
  }

  Future<void> _adjustLocation() async {
    final form = ref.read(registerDraftProvider).form;
    final initial = form.hasLocation ? (lat: form.lat!, lng: form.lng!) : null;

    // 입력칸 포커스를 풀고 간다. 풀지 않으면 돌아오는 순간 Flutter가 그 칸에
    // 포커스를 되돌려 키보드를 올리고, 닫히는 중인 지도 화면이 흔들린다.
    FocusManager.instance.primaryFocus?.unfocus();

    final picked = await context.push<LocationFix>(
      AppRoute.registerLocation,
      extra: initial,
    );
    if (picked == null) return;

    await _notifier.setLocation(lat: picked.lat, lng: picked.lng);
  }

  /// 실종 날짜. 앞으로의 날짜는 고를 수 없다.
  Future<void> _pickDate() async {
    final current = ref.read(registerDraftProvider).form.missingAt;
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: '실종된 날짜',
    );
    if (date == null) return;

    _notifier.setMissingAt(
      DateTime(date.year, date.month, date.day, current.hour, current.minute),
    );
  }

  Future<void> _pickTime() async {
    final current = ref.read(registerDraftProvider).form.missingAt;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: '실종된 시각',
    );
    if (time == null) return;

    _notifier.setMissingAt(
      DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    // 성공하면 이 화면은 사라진다. 메신저를 미리 잡아둔다.
    final messenger = ScaffoldMessenger.of(context);
    final registered = await _notifier.submit();
    if (!mounted) return;

    if (registered == null) {
      await _handleFailure(messenger);
      return;
    }

    // 새 사건이 홈·목록·지도·MY에 바로 보이게 다시 받아온다.
    ref
      ..invalidate(homeFeedProvider)
      ..invalidate(missingListProvider)
      ..invalidate(mapCasesProvider)
      ..invalidate(myCasesProvider)
      ..invalidate(myProfileProvider);

    _say(messenger, '${registered.name} 님을 등록했어요');

    // 상세로 갈아탄다. 뒤로 눌러 다 쓴 폼으로 돌아가면 같은 사람을 또 올린다.
    context.pushReplacement(AppRoute.missingDetail(registered.id));
  }

  Future<void> _handleFailure(ScaffoldMessengerState messenger) async {
    final draft = ref.read(registerDraftProvider);
    final error = draft.submission.error;

    // 쓰는 사이 로그인이 풀렸다. 다시 로그인하면 쓴 그대로 한 번 더 보낸다.
    if (error is ApiException && error.isUnauthorized) {
      final session = await showLoginSheet(context);
      if (session != null && mounted) unawaited(_submit());
      return;
    }

    final first = draft.errors.keys.firstOrNull;
    if (first != null) {
      final target = _sectionKeys[first]?.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
          alignment: 0.1,
        );
      }
      return;
    }

    if (error != null) {
      _say(
        messenger,
        error is ApiException ? error.message : '등록하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(registerDraftProvider);
    final notifier = ref.read(registerDraftProvider.notifier);

    return PopScope(
      canPop: !draft.form.hasInput,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppTopBar.modal(
          '실종자 등록',
          onClose: () => unawaited(_close()),
          action: TextButton(
            key: MissingRegisterScreen.saveDraftKey,
            onPressed: draft.isSubmitting
                ? null
                : () => unawaited(_saveDraft()),
            child: const Text('임시저장'),
          ),
        ),
        body: RegisterFormView(
          draft: draft,
          sectionKeys: _sectionKeys,
          onAddPhoto: () => unawaited(notifier.addPhotos()),
          onRemovePhoto: notifier.removePhotoAt,
          onNameChanged: notifier.setName,
          onAgeChanged: notifier.setAge,
          onGenderChanged: notifier.setGender,
          onCategoryChanged: notifier.setCategory,
          onDescriptionChanged: notifier.setDescription,
          onAdjustLocation: () => unawaited(_adjustLocation()),
          onAddressChanged: notifier.setAddress,
          onPickDate: () => unawaited(_pickDate()),
          onPickTime: () => unawaited(_pickTime()),
          onHeightChanged: notifier.setHeight,
          onWeightChanged: notifier.setWeight,
        ),
        bottomNavigationBar: RegisterSubmitBar(
          submitting: draft.isSubmitting,
          onSubmit: () => unawaited(_submit()),
        ),
      ),
    );
  }
}
