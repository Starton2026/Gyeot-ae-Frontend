import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../location/location_source.dart';
import 'photo_exif.dart';

/// 사진을 어디서 가져오는지.
enum PhotoSource {
  camera,
  gallery;

  /// 방금 그 자리에서 찍었다. 지금 내 위치가 곧 목격 위치다.
  bool get isLive => this == PhotoSource.camera;
}

/// 고른 사진 한 장과 거기 딸린 사실.
class PickedPhoto {
  const PickedPhoto({
    required this.path,
    required this.source,
    this.takenAt,
    this.fix,
  });

  /// 로컬 파일 경로.
  final String path;

  final PhotoSource source;

  /// 사진에 박힌 촬영 시각. 없을 수 있다.
  final DateTime? takenAt;

  /// 사진에 박힌 촬영 좌표. 없을 수 있다.
  final LocationFix? fix;
}

/// 기기에서 사진 한 장을 고른다.
///
/// 화면이 `image_picker`를 직접 부르지 않는 이유는 두 가지다. 위젯 테스트에서
/// 네이티브 사진첩을 열 수 없고, 사진을 고르는 화면이 S4 제보와 S7 등록 둘이다.
abstract interface class PhotoPicker {
  /// 고른 사진. 사용자가 고르지 않았으면 null.
  ///
  /// **권한 거부는 정상 경로다**(CLAUDE.md 규칙). 예외를 던지지 않고 null을
  /// 돌려준다. 화면은 "안 골랐다"와 "못 골랐다"를 같게 다룬다.
  Future<PickedPhoto?> pick(PhotoSource source);
}

/// `image_picker`를 쓰는 실제 구현.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// 올리기 전에 줄이는 크기. 얼굴 대조에는 이 정도면 충분하고, 원본
  /// 그대로 올리면 통신이 느린 곳에서 제보가 끊긴다.
  ///
  /// 줄여도 EXIF는 남는다. 안드로이드는 리사이즈 후 GPS·촬영시각 태그를 다시
  /// 복사하고, iOS도 메타데이터를 붙여준다(`requestFullMetadata` 기본값).
  static const double _maxWidth = 1600;
  static const int _quality = 85;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxWidth,
        imageQuality: _quality,
      );
      if (file == null) return null;

      final facts = await readPhotoFacts(File(file.path));

      return PickedPhoto(
        path: file.path,
        source: source,
        takenAt: facts.takenAt,
        fix: facts.fix,
      );
    } on PlatformException {
      // 권한 거부, 카메라 없는 기기. 막지 않고 고르지 않은 것으로 둔다.
      return null;
    }
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) {
  return ImagePickerPhotoPicker();
});
