import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/mascot.dart';
import '../../missing/data/missing_repository.dart';
import '../../auth/presentation/widgets/login_sheet.dart';
import '../data/report.dart';
import 'widgets/report_done_notify.dart';
import 'widgets/report_done_summary.dart';

/// 제보 완료(S4-2).
///
/// **마스코트 이음이가 나오는 자리다.** 긴급 화면에서 물러나 있던 캐릭터가
/// 안도의 순간에 등장한다(설계 결정 8번).
///
/// 제보는 이미 끝났고 되돌릴 것이 없다. 그래서 이 화면은 무엇을 더 시키는
/// 자리가 아니라, 방금 한 일이 어디에 쓰이는지 알려주는 자리다.
class ReportDoneScreen extends ConsumerWidget {
  const ReportDoneScreen({required this.caseId, this.report, super.key});

  final String caseId;

  /// 방금 확정된 제보. 링크로 직접 들어오면 없을 수 있다.
  final Report? report;

  static const Key closeButtonKey = Key('report_done_close');
  static const Key mapLinkKey = Key('report_done_map_link');

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoute.missingDetail(caseId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(missingDetailProvider(caseId)).value;
    final submitted = report;

    return Scaffold(
      appBar: AppBar(
        // 밀어낸 제보창이 스택에 없는데도 뒤로 화살표가 붙는다. 닫기는
        // 오른쪽 하나뿐이어야 한다.
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: closeButtonKey,
            onPressed: () => _leave(context),
            icon: const Icon(Icons.close_rounded, size: 24),
            color: AppColors.textSecondary,
            tooltip: '닫기',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // 브랜드 문장은 아래에 붙어 있어야 한다. 화면이 짧으면
              // 그대로 밀려 내려가고 스크롤이 생긴다.
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Mascot(MascotPose.together, height: 135),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '제보가 전달되었습니다',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline0,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '보호자에게 방금 알림이 갔습니다.\n당신이 본 장면이 경로의 한 점이 됩니다.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      if (submitted != null) ...[
                        const SizedBox(height: 20),
                        ReportDoneSummary(
                          report: submitted,
                          address: ref.watch(currentLocationProvider).label,
                        ),
                      ],
                      const SizedBox(height: 13),
                      _MapLink(
                        onTap: () => context.go(AppRoute.mapForCase(caseId)),
                      ),
                      const Spacer(),
                      const _BrandQuote(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ReportDoneNotify(
        name: detail?.name,
        // 서버가 X-Device-Hash로 방금 제보를 찾아 계정에 붙인다(F-4.2.7).
        // 몇 건이 옮겨갔는지는 세션의 claimedReports에 담겨 온다.
        onLogin: () => unawaited(showLoginSheet(context)),
        // 눌러도 제보는 그대로 유효하다(F-4.2.6).
        onSkip: () => _leave(context),
      ),
    );
  }
}

/// 이동 경로 보기(F-4.2.3).
///
/// 방금 올린 점이 선 위에 얹히는 것을 보여준다. 제보가 어디에 쓰이는지
/// 말로 설명하는 것보다 한 번 보는 쪽이 빠르다.
class _MapLink extends StatelessWidget {
  const _MapLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: ReportDoneScreen.mapLinkKey,
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('지도에서 경로 보기'),
          SizedBox(width: 5),
          AppIcon(
            AppIcons.rightAngleBracket,
            size: 13,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// 브랜드 문장(F-4.2.4).
///
/// 기능이 아니라 이 서비스가 무엇을 믿는지 적는 자리다. 제보를 막 끝낸
/// 사람에게만 보인다.
class _BrandQuote extends StatelessWidget {
  const _BrandQuote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        child: Text(
          '“당신의 작은 관심이 누군가의 내일이 됩니다”',
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle0.copyWith(
            color: AppColors.textCareAccent,
            height: 1.65,
          ),
        ),
      ),
    );
  }
}
