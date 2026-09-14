import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

import '../link/case_link.dart';

/// 카카오톡으로 보내는 사건 카드 한 장.
@immutable
class CaseShareCard {
  const CaseShareCard({
    required this.caseId,
    required this.title,
    required this.description,
    required this.buttonTitle,
    this.imageUrl,
  });

  final String caseId;
  final String title;
  final String description;
  final String buttonTitle;

  /// 카드 사진. **카카오 서버가 가져가므로 밖에서 열리는 주소여야 한다.**
  /// 에뮬레이터용 `10.0.2.2`처럼 이 폰에서만 닿는 주소면 사진 없이 간다.
  final String? imageUrl;
}

enum ShareResult {
  /// 카카오톡을 띄웠다. 실제로 보냈는지는 카카오톡 안의 일이라 모른다.
  opened,

  /// 이 폰에 카카오톡이 없다.
  kakaoTalkMissing,

  failed,
}

/// 사건을 밖으로 보낸다. 앱은 이 타입만 본다.
abstract interface class CaseSharer {
  Future<ShareResult> share(CaseShareCard card);
}

/// 카카오톡 공유. 받은 사람이 [곁애에서 보기]를 누르면 앱이 그 사건 상세로
/// 열린다 — 버튼에 실은 [CaseLink.kakaoParam]이 앱 링크로 돌아온다.
///
/// 템플릿을 카카오 콘솔에 따로 만들지 않고 기본 피드 템플릿을 쓴다. 콘솔에
/// 안드로이드 플랫폼(패키지명·키 해시)만 등록돼 있으면 된다 — 로그인 때 이미
/// 해 둔 것이다.
class KakaoCaseSharer implements CaseSharer {
  const KakaoCaseSharer();

  @override
  Future<ShareResult> share(CaseShareCard card) async {
    try {
      if (!await ShareClient.instance.isKakaoTalkSharingAvailable()) {
        return ShareResult.kakaoTalkMissing;
      }

      final params = {CaseLink.kakaoParam: card.caseId};
      final link = Link(
        androidExecutionParams: params,
        iosExecutionParams: params,
      );
      final image = card.imageUrl == null ? null : Uri.tryParse(card.imageUrl!);

      await ShareClient.instance.shareDefault(
        template: FeedTemplate(
          content: Content(
            title: card.title,
            description: card.description,
            imageUrl: image,
            link: link,
          ),
          buttons: [Button(title: card.buttonTitle, link: link)],
        ),
      );

      return ShareResult.opened;
    } on Object catch (error) {
      debugPrint('카카오톡 공유 실패: $error');

      return ShareResult.failed;
    }
  }
}

final caseSharerProvider = Provider<CaseSharer>((ref) {
  return const KakaoCaseSharer();
});
