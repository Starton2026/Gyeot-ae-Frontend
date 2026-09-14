import 'package:flutter_riverpod/misc.dart';
import 'package:gyeotae/core/mock/mock_backend.dart';
import 'package:gyeotae/features/missing/data/missing_repository.dart';
import 'package:gyeotae/features/missing/data/mock_missing_repository.dart';
import 'package:gyeotae/features/my/data/my_repository.dart';
import 'package:gyeotae/features/notifications/data/notification_repository.dart';
import 'package:gyeotae/features/report/data/mock_report_repository.dart';
import 'package:gyeotae/features/report/data/report_repository.dart';

import 'fake_my_repository.dart';
import 'fake_notification_repository.dart';

/// 네트워크를 타지 않는 저장소. 사건과 제보가 같은 mock 백엔드를 본다.
///
/// **앱 provider는 이제 진짜 백엔드를 부른다.** 앱을 통째로 띄우는 테스트가
/// 이걸 안 깔면 dio가 실제로 소켓을 열고, 화면은 조용히 오류 화면이 된다.
/// "홈이 보인다"는 테스트가 오류 화면을 보고도 통과해버린다.
List<Override> offlineRepositories({
  MockBackend? backend,
  Duration latency = Duration.zero,
  NotificationRepository? notifications,
}) {
  final shared = backend ?? MockBackend.seeded();

  return [
    missingRepositoryProvider.overrideWithValue(
      MockMissingRepository(shared, latency: latency),
    ),
    reportRepositoryProvider.overrideWithValue(
      MockReportRepository(shared, latency: latency),
    ),
    myRepositoryProvider.overrideWithValue(FakeMyRepository()),
    // 탭 상단바의 알림 버튼이 앱을 띄우자마자 알림함을 부른다.
    notificationRepositoryProvider.overrideWithValue(
      notifications ?? FakeNotificationRepository(),
    ),
  ];
}
