import '../../../core/config/env.dart';
import '../../../core/format/elapsed_time.dart';
import '../../../core/share/case_sharer.dart';
import '../data/missing_case.dart';

/// 사건 상세를 카카오톡 카드 한 장으로 줄인다.
///
/// 받는 사람은 대부분 이 앱을 모른다. 제목에 누구를 찾는지, 설명에 어디서
/// 얼마나 됐는지를 적어 카드만 보고도 무슨 일인지 알게 한다. 본문이라 워드마크는
/// `곁애`로 쓴다(설계 결정 10번).
CaseShareCard caseShareCardFor(MissingCaseDetail detail) {
  final resolved = detail.status == CaseStatus.resolved;
  final where = detail.lastAddress ?? '마지막 목격 위치는 앱에서 확인';

  return CaseShareCard(
    caseId: detail.id,
    title: resolved ? '${detail.name} 님을 찾았어요' : '${detail.name} 님을 찾고 있어요',
    description: resolved
        ? '함께 봐 주셔서 고맙습니다.'
        : '${detail.ageGenderLabel} · $where · '
              '${ElapsedTime.fromMinutes(detail.elapsedMinutes).label} 경과',
    buttonTitle: '곁애에서 보기',
    imageUrl: _publicPhotoUrl(detail.photos),
  );
}

/// 공유가 안 됐을 때 알릴 말. 카카오톡을 띄웠으면 null — 그다음은 카카오톡 몫이다.
String? shareResultMessage(ShareResult result) {
  return switch (result) {
    ShareResult.opened => null,
    ShareResult.kakaoTalkMissing => '카카오톡이 설치되어 있어야 공유할 수 있어요',
    ShareResult.failed => '공유하지 못했어요. 잠시 후 다시 시도해 주세요',
  };
}

/// 카카오 서버가 가져갈 수 있는 사진 주소. 이 폰에서만 닿는 주소면 null.
String? _publicPhotoUrl(List<String> photos) {
  if (photos.isEmpty) return null;

  final url = Uri.tryParse(Env.photoUrl(photos.first));
  if (url == null || !url.hasScheme) return null;

  final host = url.host;
  final local =
      host == 'localhost' ||
      host == '10.0.2.2' ||
      host.startsWith('127.') ||
      host.startsWith('192.168.') ||
      host.startsWith('10.');

  return local ? null : url.toString();
}
