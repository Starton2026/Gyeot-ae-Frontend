import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyeotae/core/network/api_exception.dart';
import 'package:gyeotae/features/missing/data/missing_case.dart';
import 'package:gyeotae/features/notifications/data/app_notification.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';

import '../../../support/fake_http_adapter.dart';

({Dio dio, FakeHttpAdapter adapter}) _dio({
  int statusCode = 200,
  Object body = const <String, dynamic>{},
}) {
  final adapter = FakeHttpAdapter(
    statusCode: statusCode,
    body: jsonEncode(body),
  );
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;

  return (dio: dio, adapter: adapter);
}

void main() {
  test('알림함을 읽는다', () async {
    final env = _dio(
      body: {
        'count': 3,
        'unread_count': 1,
        'items': [
          {
            'id': 'n_1',
            'type': 'report',
            'missing_id': 'm_1',
            'report_id': 'r_9',
            'title': '김하준 님 목격 제보가 들어왔어요',
            'body': '유사도 82% · 인하공전 도서관 앞',
            'created_at': '2026-09-14T15:48:00+09:00',
            'read': false,
            'missing_thumbnail': '/uploads/m_1_thumb.jpg',
            'missing_status': 'active',
          },
          {
            'id': 'n_2',
            'type': 'resolved',
            'missing_id': 'm_2',
            'report_id': null,
            'title': '찾았습니다',
            'body': '제보해 주신 이순자 님을 찾았어요. 고맙습니다.',
            'created_at': '2026-09-13T09:00:00+09:00',
            'read': true,
            'missing_thumbnail': null,
            'missing_status': 'resolved',
          },
          {
            'id': 'n_3',
            'type': 'announcement',
            'missing_id': 'm_3',
            'title': '공지',
            'body': '새 종류',
            'created_at': '2026-09-12T09:00:00+09:00',
            'read': true,
          },
        ],
      },
    );

    final inbox = await HttpNotificationRepository(env.dio).fetchInbox();

    expect(env.adapter.lastRequest!.method, 'GET');
    expect(env.adapter.lastRequest!.path, '/me/notifications');

    expect(inbox.count, 3);
    expect(inbox.unreadCount, 1);

    final report = inbox.items.first;
    expect(report.kind, NotificationKind.report);
    expect(report.caseId, 'm_1');
    expect(report.reportId, 'r_9');
    expect(report.read, isFalse);
    expect(report.missingStatus, CaseStatus.active);

    expect(inbox.items[1].kind, NotificationKind.resolved);
    expect(inbox.items[1].missingThumbnail, isNull);

    // 서버가 새 종류를 보내기 시작해도 목록이 깨지지 않는다.
    expect(inbox.items.last.kind, NotificationKind.unknown);
  });

  test('열 사건이 없는 줄은 뺀다', () async {
    final env = _dio(
      body: {
        'count': 1,
        'unread_count': 1,
        'items': [
          {'id': 'n_1', 'type': 'missing', 'title': 't', 'body': 'b'},
        ],
      },
    );

    final inbox = await HttpNotificationRepository(env.dio).fetchInbox();

    expect(inbox.items, isEmpty);
  });

  test('전부 읽음은 POST로 보낸다', () async {
    final env = _dio(body: {'marked': 2, 'unread_count': 0});

    await HttpNotificationRepository(env.dio).markAllRead();

    expect(env.adapter.lastRequest!.method, 'POST');
    expect(env.adapter.lastRequest!.path, '/me/notifications/read');
  });

  test('서버 오류는 ApiException으로 바꾼다', () async {
    final env = _dio(
      statusCode: 400,
      body: {
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Authorization 또는 X-Device-Hash 헤더가 필요합니다.',
        },
      },
    );

    await expectLater(
      HttpNotificationRepository(env.dio).fetchInbox(),
      throwsA(isA<ApiException>()),
    );
  });

  test('전부 읽은 묶음은 서버처럼 모두 읽음이다', () {
    final inbox = NotificationInbox(
      count: 1,
      unreadCount: 1,
      items: [
        AppNotification(
          id: 'n_1',
          kind: NotificationKind.missing,
          caseId: 'm_1',
          title: 't',
          body: 'b',
          createdAt: DateTime(2026, 9, 14),
          read: false,
        ),
      ],
    );

    final marked = inbox.markedRead();

    expect(marked.unreadCount, 0);
    expect(marked.items.single.read, isTrue);
    expect(marked.items.single.caseId, 'm_1');
  });
}
