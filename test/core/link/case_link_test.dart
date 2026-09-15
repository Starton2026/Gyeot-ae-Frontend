import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/link/case_link.dart';

void main() {
  group('앱 링크', () {
    test('gyeotae://missing/{id}에서 사건 id를 읽는다', () {
      expect(CaseLink.caseIdFrom(Uri.parse('gyeotae://missing/m_1')), 'm_1');
    });

    test('host 없이 쓴 gyeotae:///missing/{id}도 받는다', () {
      expect(CaseLink.caseIdFrom(Uri.parse('gyeotae:///missing/m_1')), 'm_1');
    });

    test('만든 링크를 다시 읽으면 같은 사건이다', () {
      expect(CaseLink.caseIdFrom(CaseLink.appUri('m_ab12cd34')), 'm_ab12cd34');
    });

    test('사건 링크가 아니면 열지 않는다', () {
      for (final link in [
        'gyeotae://missing',
        'gyeotae://missing/m_1/report',
        'gyeotae://map/m_1',
        'https://example.com/missing/m_1',
      ]) {
        expect(CaseLink.caseIdFrom(Uri.parse(link)), isNull, reason: link);
      }
    });

    test('id 자리에 경로를 꾸겨 넣은 값은 받지 않는다', () {
      expect(CaseLink.caseIdFrom(Uri.parse('gyeotae://missing/m%2F1')), isNull);
    });
  });

  group('카카오톡 공유 링크', () {
    test('실행 인자의 missing_id를 읽는다', () {
      expect(
        CaseLink.caseIdFrom(
          Uri.parse('kakao1234abcd://kakaolink?missing_id=m_1'),
        ),
        'm_1',
      );
    });

    test('로그인 리디렉트(kakao…://oauth)는 사건 링크가 아니다', () {
      expect(
        CaseLink.caseIdFrom(Uri.parse('kakao1234abcd://oauth?code=xyz')),
        isNull,
      );
    });

    test('인자가 없으면 열지 않는다', () {
      expect(
        CaseLink.caseIdFrom(Uri.parse('kakao1234abcd://kakaolink')),
        isNull,
      );
    });
  });
}
