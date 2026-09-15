import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/push/push_messaging.dart';

void main() {
  group('PushOpen.fromData', () {
    test('사건 id가 있으면 그 사건을 연다', () {
      final open = PushOpen.fromData({
        'type': 'missing',
        'missing_id': 'm_ab12cd34',
      });

      expect(open, const PushOpen(type: 'missing', caseId: 'm_ab12cd34'));
    });

    test('발견 완료 알림도 같은 사건으로 간다', () {
      final open = PushOpen.fromData({
        'type': 'resolved',
        'missing_id': 'm_ab12cd34',
      });

      expect(open?.type, 'resolved');
      expect(open?.caseId, 'm_ab12cd34');
    });

    test('종류를 안 주면 주변 알림으로 본다', () {
      expect(PushOpen.fromData({'missing_id': 'm_1'})?.type, 'missing');
    });

    test('사건 id가 없으면 열지 않는다', () {
      // 모르는 알림에 아무 화면이나 열면 엉뚱한 곳으로 튄다.
      expect(PushOpen.fromData({'type': 'notice'}), isNull);
      expect(PushOpen.fromData(const {}), isNull);
      expect(PushOpen.fromData({'missing_id': ''}), isNull);
      expect(PushOpen.fromData({'missing_id': 42}), isNull);
      expect(PushOpen.fromData({'missing_id': null}), isNull);
    });
  });

  test('SilentPushMessaging은 아무것도 하지 않는다', () async {
    const messaging = SilentPushMessaging();

    // Firebase가 없는 자리에서도 앱이 그대로 떠야 한다.
    expect(await messaging.requestPermission(), isFalse);
    expect(await messaging.token(), isNull);
    expect(await messaging.initialOpen(), isNull);
    expect(await messaging.opens().toList(), isEmpty);
    expect(await messaging.tokenRefreshes().toList(), isEmpty);
  });
}
