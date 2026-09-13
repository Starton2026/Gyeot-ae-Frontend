import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/media/photo_picker.dart';
import 'package:image_picker/image_picker.dart';

/// 네이티브 앨범을 열지 않는 [ImagePicker].
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.paths = const [], this.error});

  final List<String> paths;
  final Object? error;

  ({double? maxWidth, int? imageQuality, int? limit})? lastCall;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    lastCall = (maxWidth: maxWidth, imageQuality: imageQuality, limit: limit);

    final failure = error;
    if (failure != null) throw failure;

    return [for (final path in paths) XFile(path)];
  }
}

void main() {
  group('앨범에서 여러 장 고르기', () {
    test('고른 순서대로 경로를 돌려준다', () async {
      final picker = _FakeImagePicker(paths: ['/a.jpg', '/b.jpg']);

      final paths = await ImagePickerPhotoPicker(picker).pickManyFromGallery(limit: 4);

      expect(paths, ['/a.jpg', '/b.jpg']);
    });

    test('남은 장수만큼만 고르게 하고, 한 장씩 고를 때처럼 줄여서 받는다', () async {
      final picker = _FakeImagePicker(paths: ['/a.jpg']);

      await ImagePickerPhotoPicker(picker).pickManyFromGallery(limit: 3);

      expect(picker.lastCall?.limit, 3);
      expect(picker.lastCall?.maxWidth, 1600);
      expect(picker.lastCall?.imageQuality, 85);
    });

    test('플랫폼이 제한을 무시하고 더 줘도 제한에서 자른다', () async {
      // limit은 플랫폼에 따라 무시될 수 있다(image_picker 문서).
      final picker = _FakeImagePicker(paths: ['/a.jpg', '/b.jpg', '/c.jpg']);

      final paths = await ImagePickerPhotoPicker(picker).pickManyFromGallery(limit: 2);

      expect(paths, ['/a.jpg', '/b.jpg']);
    });

    test('권한이 없으면 던지지 않고 빈 목록이다', () async {
      final picker = _FakeImagePicker(
        error: PlatformException(code: 'photo_access_denied'),
      );

      expect(await ImagePickerPhotoPicker(picker).pickManyFromGallery(limit: 5), isEmpty);
    });

    test('더 담을 자리가 없으면 앨범을 열지 않는다', () async {
      final picker = _FakeImagePicker(paths: ['/a.jpg']);

      final paths = await ImagePickerPhotoPicker(picker).pickManyFromGallery(limit: 0);

      expect(paths, isEmpty);
      expect(picker.lastCall, isNull);
    });
  });
}
