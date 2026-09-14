import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../core/map/kakao_map_init.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/guardian_shortcut_banner.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/map_preview_card.dart';
import '../../../core/widgets/static_kakao_map.dart';
import '../../notifications/presentation/notification_providers.dart';
import 'home_providers.dart';
import 'widgets/guardian_register_block.dart';
import 'widgets/nearby_cases_section.dart';
import 'widgets/quiet_state_card.dart';
import 'widgets/urgent_case_banner.dart';

/// 홈(S1). 로그인 없이 바로 볼 수 있다.
///
/// 위에서부터 보호자 바로가기 띠 · 긴급 배너(없으면 평상시 블록) · 지도 프리뷰 ·
/// 주변 사건 · 등록 소개 블록 순이다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: AppTopBar.brand(
        hasUnreadNotifications: ref.watch(hasUnreadNotificationsProvider),
        onNotifications: () => unawaited(context.push(AppRoute.notifications)),
      ),
      body: Column(
        children: [
          GuardianShortcutBanner(onTap: () => _goRegister(context)),
          Expanded(
            child: feed.when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => ErrorView(
                message: error is ApiException
                    ? error.message
                    : '사건을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                onRetry: () => ref.invalidate(homeFeedProvider),
              ),
              data: (data) => _HomeFeedView(
                feed: data,
                areaName: ref.watch(currentLocationProvider).areaName,
                map: StaticKakaoMap(
                  plan: homeMapPlan(data, ref.watch(currentLocationProvider)),
                  ready: ref.watch(kakaoMapReadyProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 실종자 등록(S7)을 연다.
///
/// 로그인은 여기서 묻지 않는다. 등록 화면이 먼저 열리고, 로그인하지 않았을
/// 때만 그 위에 시트를 덮는다 — 이미 로그인한 사람에게 시트를 또 띄우지 않고,
/// 로그인할 사람은 무엇을 요구하는지 뒤에 보이는 채로 로그인한다(F-6.4).
void _goRegister(BuildContext context) =>
    unawaited(context.push(AppRoute.register));

/// 사건을 다 불러온 뒤의 홈 본문.
class _HomeFeedView extends StatelessWidget {
  const _HomeFeedView({
    required this.feed,
    required this.areaName,
    required this.map,
  });

  final HomeFeed feed;
  final String? areaName;

  /// 주변 지도. 보기만 하고, 카드를 누르면 지도 탭으로 간다.
  final Widget map;

  @override
  Widget build(BuildContext context) {
    final urgent = feed.urgentCase;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (urgent == null)
            QuietStateCard(nearbyCount: feed.nearbyCount)
          else
            // TODO(S4): 제보창이 생기면 onReport를 연결한다.
            UrgentCaseBanner(summary: urgent),
          const SizedBox(height: 12),
          MapPreviewCard(
            height: 150,
            label: '내 주변 실종 ${feed.nearbyCount}건',
            map: map,
            // 지도는 탭이다. 쌓지 않고 탭을 옮긴다.
            onTap: () => context.go(AppRoute.map),
          ),
          const SizedBox(height: 22),
          NearbyCasesSection(
            cases: feed.nearbyCases,
            areaName: areaName,
            onTapCase: (summary) =>
                context.push(AppRoute.missingDetail(summary.id)),
          ),
          const SizedBox(height: 22),
          GuardianRegisterBlock(onRegister: () => _goRegister(context)),
        ],
      ),
    );
  }
}
