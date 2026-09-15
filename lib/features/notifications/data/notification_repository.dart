import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'app_notification.dart';

/// 알림함이 보는 데이터.
///
/// **명세서에 없는 경로다.** 상단바 알림 버튼(기능정의서 5.5)이 열 화면이
/// 필요해서 백엔드에 `GET /me/notifications`를 더했다.
abstract interface class NotificationRepository {
  /// 최신순 알림과 안 읽은 수. 로그인하지 않아도 부른다 — 동네 실종 신고는
  /// 계정이 아니라 기기(`X-Device-Hash`)로 온다.
  Future<NotificationInbox> fetchInbox();

  /// 내 알림을 전부 읽음으로. 알림함을 열면 부른다.
  Future<void> markAllRead();
}

class HttpNotificationRepository implements NotificationRepository {
  const HttpNotificationRepository(this._dio);

  final Dio _dio;

  @override
  Future<NotificationInbox> fetchInbox() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/me/notifications',
      );

      return NotificationInbox.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.post<Map<String, dynamic>>('/me/notifications/read');
    } on DioException catch (error) {
      throw ApiException.from(error);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return HttpNotificationRepository(ref.watch(dioProvider));
});
