import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location.dart';
import '../../../core/media/photo_picker.dart';
import '../../../core/network/api_exception.dart';
import '../data/address_lookup.dart';
import '../data/missing_case.dart';
import '../data/missing_repository.dart';
import '../data/register_draft_storage.dart';
import '../data/register_form.dart';

/// 주소 한 줄이 어떤 상태인가.
enum AddressStatus {
  /// 아직 위치가 없다.
  idle,

  /// 카카오에 묻는 중.
  looking,

  /// 찾았거나, 보호자가 적었다.
  found,

  /// 못 찾았다. 보호자가 직접 적는다.
  notFound,
}

/// 서버가 특정 칸을 짚어 거절한 이유.
typedef RegisterServerError = ({RegisterField field, String message});

/// 등록 폼(S7)이 쥐고 있는 것 전부.
class RegisterDraft {
  const RegisterDraft({
    required this.form,
    this.showErrors = false,
    this.serverError,
    this.addressStatus = AddressStatus.idle,
    this.submission = const AsyncData(null),
  });

  /// 한 사건에 올릴 수 있는 사진 수.
  static const int maxPhotos = 5;

  final RegisterForm form;

  /// 등록하기를 한 번 눌렀다. 이때부터 빠진 칸에 안내를 붙인다.
  ///
  /// 열자마자 칸마다 "입력해 주세요"가 뜨면 다그치는 화면이 된다.
  final bool showErrors;

  final RegisterServerError? serverError;

  final AddressStatus addressStatus;

  /// 등록 결과. 값이 null이면 아직 보내기 전이다.
  final AsyncValue<MissingCaseRegistration?> submission;

  bool get isSubmitting => submission.isLoading;

  bool get canAddPhoto => form.photoPaths.length < maxPhotos;

  /// 칸마다 붙일 안내. **키 순서가 화면 순서다.**
  ///
  /// 빠진 칸은 채우는 즉시 사라진다. 값에서 매번 다시 계산하기 때문이다.
  Map<RegisterField, String> get errors {
    final invalid = showErrors
        ? form.invalidFields.toSet()
        : const <RegisterField>{};
    final server = serverError;

    return {
      for (final field in RegisterField.values)
        if (server != null && server.field == field)
          field: server.message
        else if (invalid.contains(field))
          field: field.message,
    };
  }

  RegisterDraft copyWith({
    RegisterForm? form,
    bool? showErrors,
    RegisterServerError? Function()? serverError,
    AddressStatus? addressStatus,
    AsyncValue<MissingCaseRegistration?>? submission,
  }) {
    return RegisterDraft(
      form: form ?? this.form,
      showErrors: showErrors ?? this.showErrors,
      serverError: serverError == null ? this.serverError : serverError(),
      addressStatus: addressStatus ?? this.addressStatus,
      submission: submission ?? this.submission,
    );
  }
}

/// 등록 폼 한 장의 상태.
///
/// 화면을 벗어나면 버린다(`isAutoDispose`). 이어 쓰고 싶으면 임시저장을
/// 누른다 — 말없이 남겨 두면, 다음 사건을 등록할 때 앞 사람의 사진이 올라간다.
class RegisterDraftNotifier extends Notifier<RegisterDraft> {
  @override
  RegisterDraft build() {
    // 위치는 화면을 연 뒤에 도착하는 일이 흔하다. 그때 채운다.
    ref.listen(currentLocationProvider, (previous, next) => _useDevice(next));

    final now = DateTime.now();
    final form = RegisterForm(
      missingAt: DateTime(now.year, now.month, now.day, now.hour, now.minute),
    );
    final fix = ref.read(currentLocationProvider).fix;
    if (fix == null) return RegisterDraft(form: form);

    // build 안에서는 state를 바꿀 수 없다. 주소는 한 박자 뒤에 묻는다.
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(_lookupAddress(fix.lat, fix.lng));
    });

    return RegisterDraft(
      form: form.copyWith(lat: fix.lat, lng: fix.lng),
      addressStatus: AddressStatus.looking,
    );
  }

  /// 기기 위치를 목격 위치로 채운다. **비어 있을 때만.**
  ///
  /// 보호자는 사라진 자리 근처에서 등록하는 일이 많아 기본값으로 쓸 만하다.
  /// 이미 위치가 있으면(골랐거나 임시저장에서 왔으면) 덮지 않는다.
  void _useDevice(AppLocation location) {
    final fix = location.fix;
    if (fix == null || state.form.hasLocation) return;

    state = state.copyWith(
      form: state.form.copyWith(lat: fix.lat, lng: fix.lng),
      addressStatus: AddressStatus.looking,
    );
    unawaited(_lookupAddress(fix.lat, fix.lng));
  }

  Future<void> _lookupAddress(double lat, double lng) async {
    final address = await ref
        .read(addressLookupProvider)
        .addressAt(lat: lat, lng: lng);
    if (!ref.mounted) return;

    // 묻는 사이 다른 자리를 골랐으면 이 답은 옛 자리의 것이다.
    if (state.form.lat != lat || state.form.lng != lng) return;

    state = state.copyWith(
      form: address == null ? null : state.form.copyWith(address: address),
      addressStatus: address == null
          ? AddressStatus.notFound
          : AddressStatus.found,
    );
  }

  /// 지도에서 고른 자리(F-7.7). 주소를 다시 찾는다.
  Future<void> setLocation({required double lat, required double lng}) {
    state = state.copyWith(
      // 옛 주소를 남기면 새 핀과 다른 동네가 적힌다.
      form: state.form.copyWith(
        lat: lat,
        lng: lng,
        locationPicked: true,
        address: '',
      ),
      addressStatus: AddressStatus.looking,
      serverError: _clearIf(RegisterField.location),
    );

    return _lookupAddress(lat, lng);
  }

  /// 주소를 직접 적는다. 적은 순간 보호자가 손댄 위치가 된다.
  void setAddress(String address) {
    state = state.copyWith(
      form: state.form.copyWith(address: address, locationPicked: true),
    );
  }

  /// 앨범에서 여러 장을 한 번에 더한다(F-7.2). 첫 장이 대표다.
  ///
  /// **카메라는 열지 않는다.** 실종된 사람은 눈앞에 없다. 보호자가 올릴 수
  /// 있는 것은 앨범에 있는 사진뿐이다. 남은 자리만큼만 고르게 한다.
  Future<void> addPhotos() async {
    final room = RegisterDraft.maxPhotos - state.form.photoPaths.length;
    if (room < 1) return;

    final picked = await ref
        .read(photoPickerProvider)
        .pickManyFromGallery(limit: room);
    if (picked.isEmpty || !ref.mounted) return;

    // 고르는 사이 자리가 줄었을 수 있다. 넘치는 것은 버린다.
    final photos = [
      ...state.form.photoPaths,
      ...picked,
    ].take(RegisterDraft.maxPhotos).toList(growable: false);

    state = state.copyWith(
      form: state.form.copyWith(photoPaths: photos),
      // 사진이 바뀌면 "얼굴을 못 찾았다"는 옛 사진에 대한 판단이다.
      serverError: _clearIf(RegisterField.photos),
    );
  }

  void removePhotoAt(int index) {
    final photos = [...state.form.photoPaths]..removeAt(index);

    state = state.copyWith(
      form: state.form.copyWith(photoPaths: photos),
      serverError: _clearIf(RegisterField.photos),
    );
  }

  void setName(String value) =>
      _edit(RegisterField.name, state.form.copyWith(name: value));

  void setAge(String value) =>
      _edit(RegisterField.age, state.form.copyWith(age: value));

  void setGender(Gender value) =>
      _edit(RegisterField.gender, state.form.copyWith(gender: value));

  void setCategory(MissingCategory value) =>
      _edit(RegisterField.category, state.form.copyWith(category: value));

  void setDescription(String value) =>
      _edit(RegisterField.description, state.form.copyWith(description: value));

  void setHeight(String value) =>
      state = state.copyWith(form: state.form.copyWith(height: value));

  void setWeight(String value) =>
      state = state.copyWith(form: state.form.copyWith(weight: value));

  /// 실종 일시(F-7.8). 앞으로의 시각은 실종 시각이 될 수 없어 지금으로 당긴다.
  void setMissingAt(DateTime at) {
    final now = DateTime.now();

    _edit(
      RegisterField.missingAt,
      state.form.copyWith(missingAt: at.isAfter(now) ? now : at),
    );
  }

  void _edit(RegisterField field, RegisterForm form) {
    state = state.copyWith(form: form, serverError: _clearIf(field));
  }

  /// 그 칸을 짚은 서버 오류가 있으면 지운다. 고친 칸에 옛 안내가 남지 않게.
  RegisterServerError? Function()? _clearIf(RegisterField field) {
    final server = state.serverError;
    if (server == null || server.field != field) return null;

    return () => null;
  }

  /// 등록(API 명세서 5). 성공하면 등록 결과를, 아니면 null을 준다.
  ///
  /// 빈 칸이 있으면 **보내지 않는다.** 서버까지 갔다가 하나씩 돌려받으면
  /// 사진을 매번 다시 올리게 된다. 실패 사유는 `state.submission`에 남는다 —
  /// 로그인이 풀렸으면 `ApiErrorCode.unauthorized`다.
  Future<MissingCaseRegistration?> submit() async {
    if (state.isSubmitting) return null;

    if (state.form.invalidFields.isNotEmpty) {
      state = state.copyWith(showErrors: true);
      return null;
    }

    state = state.copyWith(
      showErrors: true,
      submission: const AsyncLoading(),
      serverError: () => null,
    );

    final result = await AsyncValue.guard(
      () => ref.read(missingRepositoryProvider).register(state.form.toDraft()),
    );
    if (!ref.mounted) return null;

    state = state.copyWith(
      submission: result,
      serverError: () => _serverError(result.error),
    );

    final registered = result.value;
    if (registered != null) {
      await ref.read(registerDraftStorageProvider).clear();
    }

    return registered;
  }

  RegisterServerError? _serverError(Object? error) {
    if (error is! ApiException) return null;

    final field =
        RegisterField.fromServer(error.field) ??
        (error.code == ApiErrorCode.faceNotFound ? RegisterField.photos : null);

    return field == null ? null : (field: field, message: error.message);
  }

  /// 임시저장(F-7.11). 이 기기에만 남는다.
  Future<void> saveDraft() {
    return ref.read(registerDraftStorageProvider).save(state.form);
  }

  /// 임시저장한 폼을 되살린다. 되살렸으면 true.
  ///
  /// **이미 쓰기 시작했으면 덮지 않는다.** 방금 적은 것이 사라지는 편이
  /// 옛 저장본을 못 보는 편보다 나쁘다.
  Future<bool> restoreSaved() async {
    final saved = await ref.read(registerDraftStorageProvider).load();
    if (saved == null || !ref.mounted || state.form.hasInput) return false;

    // 저장본에 위치가 없으면 그사이 받은 기기 위치를 살린다.
    final current = state.form;
    final form = saved.hasLocation
        ? saved
        : saved.copyWith(
            lat: current.lat,
            lng: current.lng,
            address: current.address,
          );

    state = state.copyWith(
      form: form,
      addressStatus: !form.hasLocation
          ? AddressStatus.idle
          : form.address.trim().isEmpty
          ? AddressStatus.looking
          : AddressStatus.found,
    );

    if (form.hasLocation && form.address.trim().isEmpty) {
      unawaited(_lookupAddress(form.lat!, form.lng!));
    }

    return true;
  }
}

final registerDraftProvider =
    NotifierProvider<RegisterDraftNotifier, RegisterDraft>(
      RegisterDraftNotifier.new,
      isAutoDispose: true,
    );
