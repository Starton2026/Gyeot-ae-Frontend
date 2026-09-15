import 'package:gyeotae/core/location/location_source.dart';
import 'package:gyeotae/core/media/photo_picker.dart';

/// 네이티브 카메라·앨범을 열지 않는 [PhotoPicker].
///
/// [path]를 null로 두면 사용자가 고르지 않은 경우다. 권한 거부도 같은 모양이라
/// 두 경우를 한 가지로 다룰 수 있다.
///
/// [takenAt]·[fix]는 사진에 박힌 EXIF다. 둘 다 null이면 EXIF가 없는 사진
/// (화면 캡처, 메신저로 받은 사진, 위치를 꺼두고 찍은 사진)이다.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.path, this.takenAt, this.fix]);

  /// 다음 [pick]이 돌려줄 경로.
  String? path;

  /// 사진에 박힌 촬영 시각.
  DateTime? takenAt;

  /// 사진에 박힌 촬영 좌표.
  LocationFix? fix;

  /// 어디서 고르려 했는지 순서대로.
  final List<PhotoSource> calls = [];

  /// 다음 [pickManyFromGallery]가 돌려줄 경로들. 비어 있으면 고르지 않은 경우다.
  ///
  /// 진짜 선택기처럼 limit에서 자른다.
  List<String> galleryPaths = const [];

  /// [pickManyFromGallery]에 넘어온 limit을 순서대로.
  final List<int> manyLimits = [];

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    calls.add(source);
    final picked = path;
    if (picked == null) return null;

    return PickedPhoto(
      path: picked,
      source: source,
      takenAt: takenAt,
      fix: fix,
    );
  }

  @override
  Future<List<String>> pickManyFromGallery({required int limit}) async {
    manyLimits.add(limit);

    return galleryPaths.take(limit).toList(growable: false);
  }
}
