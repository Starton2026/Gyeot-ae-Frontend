import 'dart:async';

import 'package:gyeotae/core/link/link_source.dart';

/// 링크가 들어온 척하는 [LinkSource].
class FakeLinkSource implements LinkSource {
  final _links = StreamController<Uri>.broadcast();

  /// 앱 링크나 카카오톡 공유 링크를 누른 척한다.
  void open(String link) => _links.add(Uri.parse(link));

  @override
  Stream<Uri> links() => _links.stream;

  Future<void> dispose() => _links.close();
}
