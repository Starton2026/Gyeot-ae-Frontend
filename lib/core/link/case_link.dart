/// 앱 밖에서 들어온 링크가 가리키는 사건.
///
/// 두 가지 링크를 받는다.
///
/// - `gyeotae://missing/m_ab12cd34` — 앱 링크. adb·QR로 시연할 때 쓴다.
/// - `kakao{앱 키}://kakaolink?missing_id=m_ab12cd34` — 카카오톡 공유 메시지의
///   [곁애에서 보기] 버튼. 공유할 때 실은 값([kakaoParam])이 그대로 돌아온다.
///
/// **모르는 링크는 열지 않는다.** 사건 id가 아닌 값으로 화면을 열면 없는 사건의
/// 오류 화면만 뜬다.
class CaseLink {
  const CaseLink._();

  /// 앱 링크 스킴. AndroidManifest·Info.plist에 같은 값이 있다.
  static const String scheme = 'gyeotae';

  /// 카카오톡 공유 실행 인자의 키.
  static const String kakaoParam = 'missing_id';

  static final RegExp _caseId = RegExp(r'^[A-Za-z0-9_-]+$');

  /// `gyeotae://missing/{id}`.
  static Uri appUri(String caseId) =>
      Uri(scheme: scheme, host: 'missing', path: '/$caseId');

  /// 링크가 가리키는 사건 id. 사건 링크가 아니면 null.
  static String? caseIdFrom(Uri uri) {
    final String? id;

    if (uri.scheme == scheme) {
      // `gyeotae://missing/m_1`은 host가 missing이고, `gyeotae:///missing/m_1`은
      // host가 비어 있다. 둘 다 받는다.
      final segments = [
        if (uri.host.isNotEmpty) uri.host,
        ...uri.pathSegments.where((segment) => segment.isNotEmpty),
      ];
      id = segments.length == 2 && segments.first == 'missing'
          ? segments.last
          : null;
    } else if (uri.scheme.startsWith('kakao') && uri.host == 'kakaolink') {
      id = uri.queryParameters[kakaoParam];
    } else {
      id = null;
    }

    return id != null && _caseId.hasMatch(id) ? id : null;
  }
}
