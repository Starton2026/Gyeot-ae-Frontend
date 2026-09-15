import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/address_lookup.dart';
import '../data/case_edit.dart';
import '../data/missing_repository.dart';
import 'case_guardian_actions.dart';
import 'register_draft_providers.dart';

/// 정보 수정 폼(S3 보호자)이 쥐고 있는 것.
///
/// 고칠 수 있는 칸만 있다. 이름·나이·성별·구분·실종 일시는 칸 자체가 없다
/// ([CaseEdit] 참고).
class CaseEditDraft {
  const CaseEditDraft({
    required this.description,
    required this.lat,
    required this.lng,
    required this.address,
    required this.height,
    required this.weight,
    this.addressStatus = AddressStatus.found,
    this.showErrors = false,
    this.saving = false,
    this.failure,
  });

  final String description;
  final double lat;
  final double lng;
  final String address;

  /// 입력칸 그대로의 글자. 비었으면 지운다.
  final String height;
  final String weight;

  final AddressStatus addressStatus;

  /// 저장을 한 번 눌렀다. 이때부터 빈 칸에 안내를 붙인다.
  final bool showErrors;

  final bool saving;

  /// 서버가 거절한 이유.
  final ApiException? failure;

  static const String descriptionRequired = '인상착의를 입력해 주세요';

  String? get descriptionError {
    final server = failure;
    if (server != null && server.field == 'description') return server.message;
    if (showErrors && description.trim().isEmpty) return descriptionRequired;

    return null;
  }

  String? get locationError {
    final server = failure;
    if (server != null && (server.field?.startsWith('last_') ?? false)) {
      return server.message;
    }

    return null;
  }

  bool get isValid => description.trim().isNotEmpty;

  CaseEdit toEdit() {
    return CaseEdit(
      description: description,
      lastLat: lat,
      lastLng: lng,
      lastAddress: address,
      heightCm: int.tryParse(height.trim()),
      weightKg: int.tryParse(weight.trim()),
    );
  }

  CaseEditDraft copyWith({
    String? description,
    double? lat,
    double? lng,
    String? address,
    String? height,
    String? weight,
    AddressStatus? addressStatus,
    bool? showErrors,
    bool? saving,
    ApiException? Function()? failure,
  }) {
    return CaseEditDraft(
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      addressStatus: addressStatus ?? this.addressStatus,
      showErrors: showErrors ?? this.showErrors,
      saving: saving ?? this.saving,
      failure: failure == null ? this.failure : failure(),
    );
  }
}

/// 사건 한 건의 정보 수정 폼.
///
/// 상세를 이미 받아 둔 뒤에만 연다. 폼을 채울 값이 상세에서 오기 때문이다.
class CaseEditNotifier extends Notifier<CaseEditDraft> {
  CaseEditNotifier(this.caseId);

  final String caseId;

  @override
  CaseEditDraft build() {
    final detail = ref.read(missingDetailProvider(caseId)).requireValue;
    final address = detail.lastAddress ?? '';

    return CaseEditDraft(
      description: detail.description,
      lat: detail.lastLat,
      lng: detail.lastLng,
      address: address,
      height: detail.heightCm?.toString() ?? '',
      weight: detail.weightKg?.toString() ?? '',
      // 주소가 없으면 적을 칸을 연다.
      addressStatus: address.isEmpty
          ? AddressStatus.notFound
          : AddressStatus.found,
    );
  }

  void setDescription(String value) {
    state = state.copyWith(description: value, failure: () => null);
  }

  void setAddress(String value) => state = state.copyWith(address: value);

  void setHeight(String value) => state = state.copyWith(height: value);

  void setWeight(String value) => state = state.copyWith(weight: value);

  /// 지도에서 다시 고른 자리. 옛 주소를 버리고 새로 찾는다.
  Future<void> setLocation({required double lat, required double lng}) async {
    state = state.copyWith(
      lat: lat,
      lng: lng,
      address: '',
      addressStatus: AddressStatus.looking,
      failure: () => null,
    );

    final address = await ref
        .read(addressLookupProvider)
        .addressAt(lat: lat, lng: lng);
    if (!ref.mounted || state.lat != lat || state.lng != lng) return;

    state = state.copyWith(
      address: address ?? '',
      addressStatus: address == null
          ? AddressStatus.notFound
          : AddressStatus.found,
    );
  }

  /// 저장. 성공하면 true — 상세·목록이 다시 받게 해 둔다.
  ///
  /// 인상착의가 비었으면 **보내지 않는다.** 서버도 막는 칸이다.
  Future<bool> save() async {
    if (state.saving) return false;
    if (!state.isValid) {
      state = state.copyWith(showErrors: true);
      return false;
    }

    state = state.copyWith(showErrors: true, saving: true, failure: () => null);

    try {
      await ref
          .read(missingRepositoryProvider)
          .updateCase(caseId, state.toEdit());
      if (!ref.mounted) return true;

      ref.read(caseGuardianActionsProvider).refreshCase(caseId);
      state = state.copyWith(saving: false);

      return true;
    } on ApiException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(saving: false, failure: () => error);
      }

      return false;
    }
  }
}

final caseEditProvider =
    NotifierProvider.family<CaseEditNotifier, CaseEditDraft, String>(
      CaseEditNotifier.new,
      isAutoDispose: true,
    );
