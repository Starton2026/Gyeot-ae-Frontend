import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_source.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/missing_repository.dart';
import 'case_edit_providers.dart';
import 'widgets/case_edit_locked_note.dart';
import 'widgets/case_edit_save_bar.dart';
import 'widgets/register_body_fields.dart';
import 'widgets/register_location_card.dart';
import 'widgets/register_text_field.dart';

/// 정보 수정(S3 보호자, API 명세서 8). 저장하면 true를 들고 닫힌다.
///
/// 등록 폼(S7)의 칸을 그대로 쓴다. 같은 사건의 같은 칸이 두 화면에서 다르게
/// 생기면 보호자가 헷갈린다. 다만 **고칠 수 있는 칸만** 둔다.
class CaseEditScreen extends ConsumerWidget {
  const CaseEditScreen({required this.caseId, super.key});

  final String caseId;

  static const Key descriptionFieldKey = Key('case_edit_description');
  static const Key addressFieldKey = Key('case_edit_address');
  static const Key heightFieldKey = Key('case_edit_height');
  static const Key weightFieldKey = Key('case_edit_weight');
  static const Key saveButtonKey = Key('case_edit_save');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(missingDetailProvider(caseId));

    // 상세를 거쳐 들어오므로 보통은 이미 있다. 링크로 바로 들어온 경우만 기다린다.
    if (!detail.hasValue) {
      return Scaffold(
        appBar: AppTopBar.modal('정보 수정', onClose: () => context.pop()),
        body: const LoadingView(),
      );
    }

    return _CaseEditForm(caseId: caseId);
  }
}

class _CaseEditForm extends ConsumerWidget {
  const _CaseEditForm({required this.caseId});

  final String caseId;

  Future<void> _adjustLocation(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(caseEditProvider(caseId));

    // 입력칸 포커스를 풀고 간다. 풀지 않으면 돌아오는 순간 키보드가 올라오며
    // 닫히는 중인 지도 화면이 흔들린다(설계 결정 — 지도 화면 크기 고정).
    FocusManager.instance.primaryFocus?.unfocus();

    final picked = await context.push<LocationFix>(
      AppRoute.locationPicker,
      extra: (lat: draft.lat, lng: draft.lng),
    );
    if (picked == null) return;

    await ref
        .read(caseEditProvider(caseId).notifier)
        .setLocation(lat: picked.lat, lng: picked.lng);
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final notifier = ref.read(caseEditProvider(caseId).notifier);
    final saved = await notifier.save();
    if (!context.mounted) return;

    if (saved) {
      context.pop(true);
      return;
    }

    // 칸을 짚은 오류는 칸 아래에 붙는다. 그 밖의 이유만 따로 알린다.
    final failure = ref.read(caseEditProvider(caseId)).failure;
    if (failure == null || failure.field != null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(caseEditProvider(caseId));
    final notifier = ref.read(caseEditProvider(caseId).notifier);

    return Scaffold(
      appBar: AppTopBar.modal('정보 수정', onClose: () => context.pop()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CaseEditLockedNote(),
            const SizedBox(height: 22),
            RegisterTextField(
              fieldKey: CaseEditScreen.descriptionFieldKey,
              label: '인상착의',
              required: true,
              value: draft.description,
              onChanged: notifier.setDescription,
              help: '새로 알게 된 옷차림이나 습관, 자주 가는 곳을 더해 주세요.',
              errorText: draft.descriptionError,
              maxLines: 5,
            ),
            const SizedBox(height: 22),
            RegisterLocationCard(
              hasLocation: true,
              address: draft.address,
              addressStatus: draft.addressStatus,
              onAdjust: () => unawaited(_adjustLocation(context, ref)),
              onAddressChanged: notifier.setAddress,
              addressFieldKey: CaseEditScreen.addressFieldKey,
              errorText: draft.locationError,
            ),
            const SizedBox(height: 22),
            RegisterBodyFields(
              height: draft.height,
              weight: draft.weight,
              onHeightChanged: notifier.setHeight,
              onWeightChanged: notifier.setWeight,
              heightFieldKey: CaseEditScreen.heightFieldKey,
              weightFieldKey: CaseEditScreen.weightFieldKey,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CaseEditSaveBar(
        saving: draft.saving,
        onSave: () => unawaited(_save(context, ref)),
        buttonKey: CaseEditScreen.saveButtonKey,
      ),
    );
  }
}
