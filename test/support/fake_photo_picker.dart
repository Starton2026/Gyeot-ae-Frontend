import 'package:gyeotae/core/media/photo_picker.dart';

/// 네이티브 카메라·앨범을 열지 않는 [PhotoPicker].
///
/// [path]를 null로 두면 사용자가 고르지 않은 경우다. 권한 거부도 같은 모양이라
/// 두 경우를 한 가지로 다룰 수 있다.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker([this.path]);

  /// 다음 [pick]이 돌려줄 경로.
  String? path;

  /// 어디서 고르려 했는지 순서대로.
  final List<PhotoSource> calls = [];

  @override
  Future<String?> pick(PhotoSource source) async {
    calls.add(source);
    return path;
  }
}
