import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/map/kakao_map_init.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/map_preview_card.dart';
import '../../../../core/widgets/static_kakao_map.dart';
import '../../../report/data/report.dart';
import '../../../report/data/report_repository.dart';
import '../missing_detail_providers.dart';
import 'report_timeline.dart';

/// 이동 경로 미니 지도(F-3.4)와 제보 타임라인(F-3.5).
///
/// 사건 정보와 따로 불러오기 때문에, 제보가 늦게 와도 사진과 인상착의는 먼저
/// 읽을 수 있다.
///
/// 보호자면 [onToggleConfirmed]·[onToggleHidden]을 받아 카드마다 확인함·숨기기를
/// 붙인다(F-3.5.13).
class DetailReportsSection extends ConsumerWidget {
  const DetailReportsSection({
    required this.caseId,
    this.onToggleConfirmed,
    this.onToggleHidden,
    super.key,
  });

  final String caseId;
  final ValueChanged<Report>? onToggleConfirmed;
  final ValueChanged<Report>? onToggleHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(caseReportsProvider(caseId));
    final highOnly = ref.watch(timelineHighOnlyProvider);

    return reports.when(
      // 숨기기·확인함 뒤 다시 받는 동안 목록을 비우지 않는다. 비우면 누른
      // 카드가 사라졌다 나타나 스크롤이 튄다.
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ErrorView(
          message: error is ApiException ? error.message : '제보를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(caseReportsProvider(caseId)),
        ),
      ),
      data: (bundle) {
        final view = TimelineView.of(bundle, highOnly: highOnly);
        // 타임라인과 같은 view로 찍는다. 번호가 어긋나 보이면 안 된다.
        final plan = caseMapPlan(bundle, view);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MapPreviewCard(
              height: 126,
              label: bundle.count == 0
                  ? '마지막 목격 위치'
                  : '제보 ${bundle.count}건으로 복원한 이동 경로',
              onTap: () => context.go(AppRoute.mapForCase(caseId)),
              map: plan == null
                  ? null
                  : StaticKakaoMap(
                      plan: plan,
                      ready: ref.watch(kakaoMapReadyProvider),
                    ),
            ),
            const SizedBox(height: 26),
            ReportTimeline(
              view: view,
              totalCount: bundle.count,
              origin: bundle.origin,
              highOnly: highOnly,
              onHighOnlyChanged: ref
                  .read(timelineHighOnlyProvider.notifier)
                  .set,
              onToggleConfirmed: onToggleConfirmed,
              onToggleHidden: onToggleHidden,
            ),
          ],
        );
      },
    );
  }
}
