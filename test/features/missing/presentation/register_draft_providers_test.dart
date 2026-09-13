import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/location/current_location.dart';
import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/missing/data/address_lookup.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/missing/data/register_draft_storage.dart';
import 'package:gyeotae/features/missing/data/register_form.dart';
import 'package:gyeotae/features/missing/presentation/register_draft_providers.dart';

import '../../../support/fake_address_lookup.dart';
import '../../../support/fake_location_source.dart';
import '../../../support/fake_photo_picker.dart';
import '../../../support/in_memory_register_draft_storage.dart';

/// 등록을 정해진 오류로 거절하는 저장소.
class _RejectingRepository extends MockMissingRepository {
  _RejectingRepository(this.error)
    : super(MockBackend.seeded(), latency: Duration.zero);

  final ApiException error;

  @override
  Future<MissingCaseRegistration> register(MissingCaseDraft draft) async =>
      throw error;
}

typedef _Env = ({
  ProviderContainer container,
  FakePhotoPicker picker,
  FakeAddressLookup lookup,
  InMemoryRegisterDraftStorage storage,
  MockBackend backend,
});

_Env _setUp({
  LocationFix? deviceFix = (lat: 37.47, lng: 126.75),
  String? address = '인천 남동구 인하로 501',
  MissingRepository? repository,
  RegisterForm? saved,
}) {
  final backend = MockBackend.seeded();
  final picker = FakePhotoPicker();
  final lookup = FakeAddressLookup(address);
  final storage = InMemoryRegisterDraftStorage(saved);

  final container = ProviderContainer.test(
    overrides: [
      photoPickerProvider.overrideWithValue(picker),
      locationSourceProvider.overrideWithValue(
        FakeLocationSource(known: deviceFix, now: deviceFix),
      ),
      addressLookupProvider.overrideWithValue(lookup),
      registerDraftStorageProvider.overrideWithValue(storage),
      missingRepositoryProvider.overrideWithValue(
        repository ?? MockMissingRepository(backend, latency: Duration.zero),
      ),
    ],
  );
  // autoDispose다. 테스트 동안 붙들어 둔다.
  container.listen(registerDraftProvider, (_, _) {});

  return (
    container: container,
    picker: picker,
    lookup: lookup,
    storage: storage,
    backend: backend,
  );
}

RegisterDraftNotifier _notifier(_Env env) =>
    env.container.read(registerDraftProvider.notifier);

RegisterDraft _draft(_Env env) => env.container.read(registerDraftProvider);

/// 기기 위치가 도착하고 주소 조회까지 끝나기를 기다린다.
Future<void> _settle(_Env env) async {
  await env.container.read(currentLocationProvider.notifier).locate();
  await Future<void>.delayed(Duration.zero);
}

/// 필수 칸을 전부 채운다.
Future<void> _fillAll(_Env env) async {
  final notifier = _notifier(env);

  env.picker.galleryPaths = ['/tmp/a.jpg'];
  await notifier.addPhotos();
  notifier
    ..setName('김하준')
    ..setAge('7')
    ..setGender(Gender.male)
    ..setCategory(MissingCategory.child)
    ..setDescription('노란 후드티');
  await notifier.setLocation(lat: 37.4491, lng: 126.7312);
}

void main() {
  group('마지막 목격 위치(F-7.7)', () {
    test('기기 위치를 받으면 채우고 주소를 찾는다', () async {
      final env = _setUp();
      await _settle(env);

      final draft = _draft(env);
      expect(draft.form.lat, 37.47);
      expect(draft.form.lng, 126.75);
      expect(draft.form.address, '인천 남동구 인하로 501');
      expect(draft.addressStatus, AddressStatus.found);
      // 저절로 들어간 위치다. 보호자가 쓴 것이 아니다.
      expect(draft.form.hasInput, isFalse);
    });

    test('위치를 못 받으면 지어내지 않고 비워 둔다', () async {
      final env = _setUp(deviceFix: null);
      await _settle(env);

      // 시연용 기본 좌표를 실종 위치로 넣으면 엉뚱한 곳에 핀이 꽂힌다.
      expect(_draft(env).form.hasLocation, isFalse);
      expect(env.lookup.calls, isEmpty);
    });

    test('지도에서 고르면 그 자리로 바꾸고 주소를 다시 찾는다', () async {
      final env = _setUp();
      await _settle(env);
      env.lookup.address = '인천 남동구 구월동 1138';

      await _notifier(env).setLocation(lat: 37.45, lng: 126.73);

      final draft = _draft(env);
      expect((draft.form.lat, draft.form.lng), (37.45, 126.73));
      expect(draft.form.locationPicked, isTrue);
      expect(draft.form.address, '인천 남동구 구월동 1138');
      expect(env.lookup.calls.last, (lat: 37.45, lng: 126.73));
    });

    test('고른 뒤에는 기기 위치가 와도 덮지 않는다', () async {
      final env = _setUp(deviceFix: null);
      await _notifier(env).setLocation(lat: 37.45, lng: 126.73);

      final source =
          env.container.read(locationSourceProvider) as FakeLocationSource;
      source.now = (lat: 37.47, lng: 126.75);
      await _settle(env);

      expect(_draft(env).form.lat, 37.45);
    });

    test('주소를 못 찾으면 직접 적게 한다', () async {
      final env = _setUp(address: null);

      await _notifier(env).setLocation(lat: 37.45, lng: 126.73);

      expect(_draft(env).addressStatus, AddressStatus.notFound);
      expect(_draft(env).form.address, isEmpty);

      _notifier(env).setAddress('구월동 로데오거리');
      expect(_draft(env).form.address, '구월동 로데오거리');
    });

    test('다른 자리를 고르면 앞서 찾은 주소는 버린다', () async {
      final env = _setUp();
      await _notifier(env).setLocation(lat: 37.45, lng: 126.73);
      env.lookup.address = null;

      await _notifier(env).setLocation(lat: 37.50, lng: 126.80);

      // 옛 주소가 남으면 새 핀과 다른 동네가 적힌다.
      expect(_draft(env).form.address, isEmpty);
    });
  });

  group('사진(F-7.2)', () {
    test('앨범에서 여러 장을 한 번에 고르면 고른 순서대로 쌓인다', () async {
      final env = _setUp();
      env.picker.galleryPaths = ['/tmp/a.jpg', '/tmp/b.jpg'];

      await _notifier(env).addPhotos();

      // 첫 장이 대표다.
      expect(_draft(env).form.photoPaths, ['/tmp/a.jpg', '/tmp/b.jpg']);
      // 실종된 사람을 카메라로 찍을 수는 없다. 앨범만 연다.
      expect(env.picker.calls, isEmpty);
    });

    test('더 고르면 뒤에 붙는다', () async {
      final env = _setUp();
      env.picker.galleryPaths = ['/tmp/a.jpg'];
      await _notifier(env).addPhotos();

      env.picker.galleryPaths = ['/tmp/b.jpg', '/tmp/c.jpg'];
      await _notifier(env).addPhotos();

      expect(_draft(env).form.photoPaths, ['/tmp/a.jpg', '/tmp/b.jpg', '/tmp/c.jpg']);
    });

    test('고르지 않으면 그대로다', () async {
      final env = _setUp();

      await _notifier(env).addPhotos();

      expect(_draft(env).form.photoPaths, isEmpty);
    });

    test('남은 자리만큼만 고르게 한다', () async {
      final env = _setUp();
      env.picker.galleryPaths = ['/tmp/a.jpg', '/tmp/b.jpg'];
      await _notifier(env).addPhotos();

      env.picker.galleryPaths = [for (var i = 0; i < 6; i++) '/tmp/$i.jpg'];
      await _notifier(env).addPhotos();

      expect(env.picker.manyLimits, [RegisterDraft.maxPhotos, RegisterDraft.maxPhotos - 2]);
      expect(_draft(env).form.photoPaths, hasLength(RegisterDraft.maxPhotos));
      expect(_draft(env).canAddPhoto, isFalse);
    });

    test('다 찼으면 앨범을 열지 않는다', () async {
      final env = _setUp();
      env.picker.galleryPaths = [for (var i = 0; i < 5; i++) '/tmp/$i.jpg'];
      await _notifier(env).addPhotos();

      await _notifier(env).addPhotos();

      expect(env.picker.manyLimits, hasLength(1));
    });

    test('뺄 수 있다', () async {
      final env = _setUp();
      env.picker.galleryPaths = ['/tmp/a.jpg', '/tmp/b.jpg'];
      await _notifier(env).addPhotos();

      _notifier(env).removePhotoAt(0);

      // 첫 장을 빼면 다음 장이 대표가 된다.
      expect(_draft(env).form.photoPaths, ['/tmp/b.jpg']);
    });
  });

  group('입력', () {
    test('실종 일시는 앞으로의 시각이 될 수 없다', () {
      final env = _setUp();

      _notifier(env).setMissingAt(DateTime.now().add(const Duration(hours: 2)));

      expect(_draft(env).form.missingAt.isAfter(DateTime.now()), isFalse);
    });
  });

  group('등록', () {
    test('빈 칸이 있으면 보내지 않고 빠진 칸을 알린다', () async {
      final env = _setUp(deviceFix: null);
      _notifier(env).setName('김하준');

      final result = await _notifier(env).submit();

      expect(result, isNull);
      final draft = _draft(env);
      expect(draft.errors.keys.first, RegisterField.photos);
      expect(draft.errors.containsKey(RegisterField.name), isFalse);
      expect(
        draft.errors[RegisterField.location],
        RegisterField.location.message,
      );
    });

    test('등록하기를 누르기 전에는 빨간 안내가 없다', () {
      final env = _setUp();

      // 열자마자 칸마다 "입력해 주세요"가 뜨면 다그치는 화면이 된다.
      expect(_draft(env).errors, isEmpty);
    });

    test('빠졌던 칸을 채우면 그 안내만 사라진다', () async {
      final env = _setUp(deviceFix: null);
      await _notifier(env).submit();

      _notifier(env).setName('김하준');

      expect(_draft(env).errors.containsKey(RegisterField.name), isFalse);
      expect(_draft(env).errors.containsKey(RegisterField.age), isTrue);
    });

    test('다 채우면 등록하고 임시저장을 지운다', () async {
      final env = _setUp();
      await _notifier(env).saveDraft();
      await _fillAll(env);

      final result = await _notifier(env).submit();

      expect(result, isNotNull);
      final registered = await env.container
          .read(missingRepositoryProvider)
          .fetchCase(result!.id);
      expect(registered.name, '김하준');
      expect(registered.lastAddress, '인천 남동구 인하로 501');
      expect(env.storage.saved, isNull);
    });

    test('얼굴을 못 찾으면 사진 칸에 서버의 말을 적는다', () async {
      const message = '사진에서 얼굴을 찾지 못했습니다. 얼굴이 잘 보이는 사진을 한 장 이상 올려주세요.';
      final env = _setUp(
        repository: _RejectingRepository(
          const ApiException(
            message,
            statusCode: 400,
            code: ApiErrorCode.faceNotFound,
            field: 'photos',
          ),
        ),
      );
      await _fillAll(env);

      expect(await _notifier(env).submit(), isNull);
      expect(_draft(env).errors[RegisterField.photos], message);

      // 사진을 바꾸면 그 판단은 옛 사진의 것이다.
      env.picker.galleryPaths = ['/tmp/front.jpg'];
      await _notifier(env).addPhotos();
      expect(_draft(env).errors, isEmpty);
    });

    test('로그인이 풀렸으면 쓴 내용을 두고 오류만 남긴다', () async {
      final env = _setUp(
        repository: _RejectingRepository(
          const ApiException(
            '토큰이 없거나 만료되었습니다.',
            statusCode: 401,
            code: ApiErrorCode.unauthorized,
          ),
        ),
      );
      await _fillAll(env);

      expect(await _notifier(env).submit(), isNull);

      final draft = _draft(env);
      expect(
        (draft.submission.error as ApiException?)?.code,
        ApiErrorCode.unauthorized,
      );
      expect(draft.form.name, '김하준');
      expect(draft.isSubmitting, isFalse);
    });
  });

  group('임시저장(F-7.11)', () {
    test('지금 쓴 것을 기기에 적어 둔다', () async {
      final env = _setUp();
      _notifier(env).setName('김하준');

      await _notifier(env).saveDraft();

      expect(env.storage.saved?.name, '김하준');
    });

    test('다시 열면 이어 쓴다', () async {
      final env = _setUp(
        saved: RegisterForm(
          missingAt: DateTime(2026, 9, 14, 14, 40),
          name: '김하준',
          lat: 37.45,
          lng: 126.73,
          locationPicked: true,
          address: '구월동 로데오거리',
        ),
      );

      final restored = await _notifier(env).restoreSaved();
      await _settle(env);

      expect(restored, isTrue);
      final draft = _draft(env);
      expect(draft.form.name, '김하준');
      // 저장해 둔 자리를 기기 위치로 덮지 않는다.
      expect(draft.form.lat, 37.45);
      expect(draft.form.address, '구월동 로데오거리');
    });

    test('이미 쓰기 시작했으면 덮지 않는다', () async {
      final env = _setUp(
        saved: RegisterForm(missingAt: DateTime(2026, 9, 14), name: '옛 이름'),
      );
      _notifier(env).setName('새 이름');

      expect(await _notifier(env).restoreSaved(), isFalse);
      expect(_draft(env).form.name, '새 이름');
    });

    test('저장한 것이 없으면 아무 일도 없다', () async {
      final env = _setUp();

      expect(await _notifier(env).restoreSaved(), isFalse);
    });
  });
}
