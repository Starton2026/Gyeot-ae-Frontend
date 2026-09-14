import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 앱을 연 링크. 앱은 이 타입만 본다.
///
/// 링크를 받는 자리를 하나로 모아, 테스트에서 갈아끼울 수 있게 한다.
abstract interface class LinkSource {
  /// 앱을 **처음 띄운** 링크와, 떠 있는 동안 들어온 링크를 차례로.
  Stream<Uri> links();
}

/// 진짜 링크. 앱 링크와 카카오톡 공유 링크를 함께 받는다.
///
/// Flutter 기본 딥링크는 꺼 뒀다(AndroidManifest·Info.plist). 켜 두면 라우터가
/// 링크로 곧장 가면서 스플래시를 건너뛰고, 여기서 한 번 더 열어 상세가 두 겹
/// 쌓인다.
class AppLinkSource implements LinkSource {
  const AppLinkSource();

  @override
  Stream<Uri> links() => AppLinks().uriLinkStream;
}

/// 아무 링크도 오지 않는다. 테스트처럼 네이티브 쪽이 없는 자리에서 쓴다.
class SilentLinkSource implements LinkSource {
  const SilentLinkSource();

  @override
  Stream<Uri> links() => const Stream.empty();
}

/// 기본은 조용한 구현이고, `main`이 진짜로 갈아끼운다. 테스트가 앱을 띄울 때
/// 네이티브 채널을 부르면 그 자리에서 실패한다.
final linkSourceProvider = Provider<LinkSource>((ref) {
  return const SilentLinkSource();
});
