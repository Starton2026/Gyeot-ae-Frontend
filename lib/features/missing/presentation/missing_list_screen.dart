import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/guardian_shortcut_banner.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/missing_case_tile.dart';
import 'missing_list_providers.dart';
import 'widgets/missing_empty_view.dart';
import 'widgets/missing_filter_chips.dart';
import 'widgets/missing_list_header.dart';
import 'widgets/missing_search_field.dart';
import 'widgets/missing_sort_sheet.dart';

/// 실종자 목록(S2). 로그인 없이 볼 수 있다.
///
/// 홈의 주변 목록이 3건 고정인 것과 달리 여기는 검색·필터·정렬을 모두 연다.
/// 발견 완료된 사건도 지우지 않고 투명도만 낮춰 남긴다(설계 결정 7번).
class MissingListScreen extends ConsumerStatefulWidget {
  const MissingListScreen({super.key});

  @override
  ConsumerState<MissingListScreen> createState() => _MissingListScreenState();
}

class _MissingListScreenState extends ConsumerState<MissingListScreen> {
  /// 목록 끝이 이만큼 남으면 다음 장을 부른다.
  static const double _loadMoreThreshold = 400;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > _loadMoreThreshold) return;

    ref.read(missingListProvider.notifier).loadMore();
  }

  Future<void> _pickSort() async {
    final query = ref.read(missingListQueryProvider);
    final picked = await showMissingSortSheet(context, current: query.sort);
    if (picked == null) return;

    ref.read(missingListQueryProvider.notifier).setSort(picked);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(missingListQueryProvider);
    final list = ref.watch(missingListProvider);
    final page = list.value;

    return Scaffold(
      appBar: const AppTopBar.title('실종자'),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.missing,
        onSelect: (tab) => context.go(tab.path!),
      ),
      body: Column(
        children: [
          GuardianShortcutBanner(
            onTap: () => context.push(AppRoute.login),
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MissingSearchField(
                          onChanged: ref
                              .read(missingListQueryProvider.notifier)
                              .setKeyword,
                        ),
                        const SizedBox(height: 11),
                        MissingFilterChips(
                          selected: query.filter,
                          onSelect: ref
                              .read(missingListQueryProvider.notifier)
                              .setFilter,
                        ),
                        const SizedBox(height: 10),
                        MissingListHeader(
                          filter: query.filter,
                          count: page?.count ?? 0,
                          sort: query.sort,
                          onTapSort: _pickSort,
                        ),
                      ],
                    ),
                  ),
                ),
                ..._bodySlivers(list, page, query.keyword),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 목록 본문. 이미 받아둔 목록이 있으면 새로 불러오는 중에도 그대로 둔다.
  List<Widget> _bodySlivers(
    AsyncValue<MissingListPage> list,
    MissingListPage? page,
    String keyword,
  ) {
    if (page == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: list.hasError
              ? ErrorView(
                  message: list.error is ApiException
                      ? (list.error! as ApiException).message
                      : '목록을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
                  onRetry: () => ref.invalidate(missingListProvider),
                )
              : const LoadingView(),
        ),
      ];
    }

    if (page.items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MissingEmptyView(keyword: keyword),
        ),
      ];
    }

    return [
      SliverPadding(
        // 마지막 항목도 자기 위아래 여백(14)을 그대로 갖는다. 여기에 더 얹으면
        // 목록이 네비게이션 바 위에 떠 있는 것처럼 보인다.
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverList.separated(
          itemCount: page.items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => MissingCaseTile(
            summary: page.items[index],
            variant: MissingCaseTileVariant.detailed,
            onTap: () => context.push(
              AppRoute.missingDetail(page.items[index].id),
            ),
          ),
        ),
      ),
      if (page.isLoadingMore)
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ),
        ),
    ];
  }
}
