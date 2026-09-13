import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/missing/data/register_form.dart';

final _missingAt = DateTime(2026, 9, 14, 14, 40);

/// 필수 항목을 전부 채운 폼.
RegisterForm _filled() => RegisterForm(
  missingAt: _missingAt,
  photoPaths: const ['/tmp/a.jpg', '/tmp/b.jpg'],
  name: ' 김하준 ',
  age: '7',
  gender: Gender.male,
  category: MissingCategory.child,
  description: '노란 후드티',
  lat: 37.4491,
  lng: 126.7312,
  address: '인천 남동구 인하로 501',
);

void main() {
  group('검증', () {
    test('다 채우면 빠진 것이 없다', () {
      expect(_filled().invalidFields, isEmpty);
    });

    test('빈 폼은 필수 항목이 화면 순서대로 빠져 있다', () {
      final form = RegisterForm(missingAt: _missingAt);

      // 첫 번째로 빠진 칸으로 스크롤하므로 순서가 곧 화면 순서여야 한다.
      expect(form.invalidFields, [
        RegisterField.photos,
        RegisterField.name,
        RegisterField.age,
        RegisterField.gender,
        RegisterField.category,
        RegisterField.description,
        RegisterField.location,
      ]);
    });

    test('공백만 적은 칸은 빈 칸이다', () {
      final form = _filled().copyWith(name: '   ', description: '\n ');

      expect(form.invalidFields, [
        RegisterField.name,
        RegisterField.description,
      ]);
    });

    test('나이는 숫자여야 한다', () {
      expect(_filled().copyWith(age: '일곱').invalidFields, [RegisterField.age]);
      expect(_filled().copyWith(age: '200').invalidFields, [RegisterField.age]);
      expect(_filled().copyWith(age: '0').invalidFields, isEmpty);
    });

    test('주소와 키·몸무게는 비워도 된다', () {
      final form = _filled().copyWith(address: '', height: '', weight: '');

      expect(form.invalidFields, isEmpty);
    });
  });

  group('서버로 보낼 값', () {
    test('다듬어서 명세서 5)의 필드로 옮긴다', () {
      final draft = _filled().copyWith(height: '122', weight: '24').toDraft();

      expect(draft.name, '김하준');
      expect(draft.age, 7);
      expect(draft.gender, Gender.male);
      expect(draft.category, MissingCategory.child);
      expect(draft.lastLat, 37.4491);
      expect(draft.lastLng, 126.7312);
      expect(draft.lastAddress, '인천 남동구 인하로 501');
      expect(draft.missingAt, _missingAt);
      expect(draft.photoPaths, ['/tmp/a.jpg', '/tmp/b.jpg']);
      expect(draft.heightCm, 122);
      expect(draft.weightKg, 24);
    });

    test('비운 선택 항목은 보내지 않는다', () {
      final draft = _filled()
          .copyWith(address: ' ', height: '', weight: '키')
          .toDraft();

      // 빈 주소를 보내면 서버가 빈 문자열을 주소로 저장한다.
      expect(draft.lastAddress, isNull);
      expect(draft.heightCm, isNull);
      expect(draft.weightKg, isNull);
    });

    test('필수 항목이 빠졌으면 만들지 않는다', () {
      expect(
        () => RegisterForm(missingAt: _missingAt).toDraft(),
        throwsStateError,
      );
    });
  });

  group('서버 오류의 field', () {
    test('명세서의 필드 이름을 폼의 칸으로 바꾼다', () {
      expect(RegisterField.fromServer('photos'), RegisterField.photos);
      expect(RegisterField.fromServer('age'), RegisterField.age);
      expect(RegisterField.fromServer('last_lat'), RegisterField.location);
      expect(RegisterField.fromServer('last_lng'), RegisterField.location);
      expect(RegisterField.fromServer('missing_at'), RegisterField.missingAt);
      // 보호자 연락처는 더 받지 않는다. 옛 서버가 짚어도 칸이 없다.
      expect(RegisterField.fromServer('guardian_phone'), isNull);
      expect(RegisterField.fromServer('mystery'), isNull);
      expect(RegisterField.fromServer(null), isNull);
    });
  });

  group('임시저장', () {
    test('JSON으로 옮겼다가 그대로 되살린다', () {
      final form = _filled().copyWith(height: '122', locationPicked: true);

      final restored = RegisterForm.fromJson(form.toJson());

      expect(restored.photoPaths, form.photoPaths);
      expect(restored.name, form.name);
      expect(restored.age, form.age);
      expect(restored.gender, form.gender);
      expect(restored.category, form.category);
      expect(restored.description, form.description);
      expect(restored.lat, form.lat);
      expect(restored.lng, form.lng);
      expect(restored.locationPicked, isTrue);
      expect(restored.address, form.address);
      expect(restored.missingAt, form.missingAt);
      expect(restored.height, '122');
    });

    test('아무것도 안 고른 칸은 비어서 돌아온다', () {
      final restored = RegisterForm.fromJson(
        RegisterForm(missingAt: _missingAt).toJson(),
      );

      expect(restored.gender, isNull);
      expect(restored.category, isNull);
      expect(restored.lat, isNull);
      expect(restored.photoPaths, isEmpty);
    });
  });

  group('쓰던 내용', () {
    test('빈 폼에는 쓰던 내용이 없다', () {
      expect(RegisterForm(missingAt: _missingAt).hasInput, isFalse);
    });

    test('기기 위치와 그 주소가 저절로 채워진 것은 쓴 것이 아니다', () {
      final form = RegisterForm(
        missingAt: _missingAt,
        lat: 37.4,
        lng: 126.7,
        address: '인천 남동구 인하로 501',
      );

      expect(form.hasInput, isFalse);
    });

    test('한 칸이라도 채우면 쓰던 내용이 있다', () {
      expect(RegisterForm(missingAt: _missingAt, name: '김').hasInput, isTrue);
      expect(
        RegisterForm(
          missingAt: _missingAt,
          photoPaths: const ['/tmp/a.jpg'],
        ).hasInput,
        isTrue,
      );
      expect(
        RegisterForm(
          missingAt: _missingAt,
          lat: 37.4,
          lng: 126.7,
          locationPicked: true,
        ).hasInput,
        isTrue,
      );
    });
  });
}
