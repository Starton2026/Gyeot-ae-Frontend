import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/guardian_shortcut_banner.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/map_preview_card.dart';
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
      appBar: const AppTopBar.brand(),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 실종자 등록(S7)은 로그인이 필요하다. 등록을 누른 사람에게만 로그인을 묻는다.
///
/// TODO(S7): 등록 화면이 생기면 로그인 성공 후 등록으로 이어지게 한다.
void _goRegister(BuildContext context) => context.push(AppRoute.login);

/// 사건을 다 불러온 뒤의 홈 본문.
class _HomeFeedView extends StatelessWidget {
  const _HomeFeedView({required this.feed, required this.areaName});

  final HomeFeed feed;
  final String? areaName;

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
          // TODO(S5): 지도 탭이 생기면 onTap을 연결한다.
          MapPreviewCard(
            height: 150,
            label: '내 주변 실종 ${feed.nearbyCount}건',
          ),
          const SizedBox(height: 22),
          // TODO(S2): 목록 화면이 생기면 onTapMore를 연결한다.
          NearbyCasesSection(
            cases: feed.nearbyCases,
            areaName: areaName,
            totalCount: feed.activeCount,
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
