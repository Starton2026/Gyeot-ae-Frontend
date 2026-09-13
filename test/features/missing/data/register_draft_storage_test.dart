import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/features/missing/data/register_draft_storage.dart';
import 'package:gyeotae/features/missing/data/register_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _form = RegisterForm(
  missingAt: DateTime(2026, 9, 14, 14, 40),
  photoPaths: const ['/cache/a.jpg', '/cache/gone.jpg'],
  name: '김하준',
  description: '노란 후드티',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('저장한 적이 없으면 null이다', () async {
    expect(await PrefsRegisterDraftStorage().load(), isNull);
  });

  test('저장한 폼을 다시 읽는다', () async {
    final storage = PrefsRegisterDraftStorage(fileExists: (_) => true);

    await storage.save(_form);
    final loaded = await storage.load();

    expect(loaded?.name, '김하준');
    expect(loaded?.description, '노란 후드티');
    expect(loaded?.photoPaths, ['/cache/a.jpg', '/cache/gone.jpg']);
  });

  test('그사이 지워진 사진은 빼고 되살린다', () async {
    // image_picker가 준 경로는 캐시라 OS가 치울 수 있다. 없는 파일을 올리면
    // 등록이 통째로 실패한다.
    final storage = PrefsRegisterDraftStorage(
      fileExists: (path) => path != '/cache/gone.jpg',
    );

    await storage.save(_form);
    final loaded = await storage.load();

    expect(loaded?.photoPaths, ['/cache/a.jpg']);
    expect(loaded?.name, '김하준');
  });

  test('지우면 다시 읽어도 없다', () async {
    final storage = PrefsRegisterDraftStorage(fileExists: (_) => true);

    await storage.save(_form);
    await storage.clear();

    expect(await storage.load(), isNull);
  });

  test('깨진 값이 남아 있으면 없는 것으로 친다', () async {
    SharedPreferences.setMockInitialValues({'register_draft': '{not json'});

    expect(await PrefsRegisterDraftStorage().load(), isNull);
  });
}
