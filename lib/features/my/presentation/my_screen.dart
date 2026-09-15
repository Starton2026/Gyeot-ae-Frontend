import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/resolve_case_dialog.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../home/presentation/home_providers.dart';
import '../../map/presentation/map_providers.dart';
import '../../missing/data/missing_case.dart';
import '../../missing/data/missing_repository.dart';
import '../../missing/presentation/missing_list_providers.dart';
import '../../notifications/presentation/notification_providers.dart';
import '../data/my_report.dart';
import '../data/my_repository.dart';
import 'my_providers.dart';
import 'widgets/my_case_card.dart';
import 'widgets/my_device_note.dart';
import 'widgets/my_folded_list.dart';
import 'widgets/my_login_card.dart';
import 'widgets/my_menu.dart';
import 'widgets/my_profile_header.dart';
import 'widgets/my_report_tile.dart';
import 'widgets/my_section_header.dart';
import 'widgets/my_sign_out_dialog.dart';

/// MY(S8). 로그인 여부로 위쪽만 갈린다.
///
/// **게스트에게도 빈 화면을 주지 않는다.** 로그인 버튼만 덩그러니 두면 MY는
/// 죽은 탭이 된다. 제보는 로그인 없이 하는 것이 기본이므로(설계 결정 1번),
/// 게스트도 자기가 무엇을 보냈는지는 볼 수 있어야 한다(F-8.2). 서버가
/// `X-Device-Hash`로 그 이력을 찾아준다.
///
/// TODO(S8): 재등록(F-8.5)은 등록 폼(S7)이 생겨야 의미가 있다. 서버는
/// `GET /missing/{id}/duplicate`로 채워줄 값을 주기로 되어 있다.
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  /// 접기 전에 보여줄 지난 사건 수.
  ///
  /// 끝난 사건은 지우지 않지만(설계 결정 7번) 진행 중인 사건보다 위로
  /// 올라오면 안 되고, 길어져서 아래 메뉴를 밀어내서도 안 된다.
  static const int pastCasesPreview = 3;

  /// 접기 전에 보여줄 제보 이력 수.
  ///
  /// MY에서 유일하게 수십 건까지 쌓이는 목록이다. 제보는 로그인 없이 할 수
  /// 있어서(설계 결정 1번) 열심히 쓰는 사람일수록 빨리 늘어난다.
  static const int reportsPreview = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final topBar = AppTopBar.title(
      'MY',
      hasUnreadNotifications: ref.watch(hasUnreadNotificationsProvider),
      onNotifications: () => unawaited(context.push(AppRoute.notifications)),
    );

    // 저장된 토큰으로 누구인지 서버에 묻는 중이다. 이때 값이 비어 있다고
    // 게스트 화면을 그리면, 로그인한 사람에게 로그인 권유가 잠깐 번쩍였다가
    // 프로필로 바뀐다. 한 번 확인한 뒤의 새로고침은 옛 값을 들고 있어서
    // 여기에 걸리지 않는다.
    //
    // 실패했으면 기다리지 않는다. Riverpod이 40초 넘게 다시 시도하는데, 그동안
    // 로딩만 돌리면 MY가 통째로 멈춘 것처럼 보인다.
    if (!auth.hasValue && !auth.hasError) {
      return Scaffold(appBar: topBar, body: const LoadingView());
    }

    final user = auth.value;
    final profile = ref.watch(myProfileProvider).value;
    final reports = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: topBar,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          if (user == null)
            const _GuestLogin()
          else
            MyProfileHeader(
              name: user.name,
              photoUrl: user.profileImageUrl,
              caseCount: profile?.caseCount ?? 0,
              // 프로필이 아직 안 왔으면 목록이 센 값이라도 적는다.
              reportCount: profile?.reportCount ?? reports.value?.count ?? 0,
            ),
          if (user != null) const _MyCases(),
          MySectionHeader(
            // 게스트에게는 "내"가 아니라 "이 기기"다. 계정이 없으니 이력의
            // 주인도 계정이 아니라 기기다.
            title: user == null ? '이 기기에서 한 제보' : '내 제보 이력',
            trailing: reports.value == null ? null : '${reports.value!.count}건',
          ),
          _MyReports(reports: reports),
          if (user == null) ...[
            const SizedBox(height: 18),
            const MyDeviceNote(),
          ],
          const SizedBox(height: 8),
          MyMenu(
            signedIn: user != null,
            onNotificationSettings: () =>
                unawaited(context.push(AppRoute.notificationSettings)),
            onSignOut: () => unawaited(_signOut(context, ref)),
          ),
        ],
      ),
    );
  }

  /// 한 번 묻고 로그아웃한다. 화면은 로그인 상태를 지켜보고 있어서 게스트
  /// 화면으로 알아서 다시 그려진다.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    if (!await MySignOutDialog.show(context)) return;

    await ref.read(authProvider.notifier).signOut();
  }
}

/// 게스트의 로그인 카드. **시트를 거치지 않고 바로 카카오로 간다.**
///
/// 로그인 시트(S6)는 등록처럼 하던 일 위에 끼어들 때 쓰는 것이다. MY에서는
/// 카드가 이미 로그인하면 무엇이 좋은지 말했으므로, 시트를 또 띄우면 같은
/// 말을 두 번 보고 버튼을 두 번 누르게 된다.
///
/// 성공하면 로그인 상태가 바뀌어 화면이 알아서 프로필로 다시 그려진다.
class _GuestLogin extends ConsumerStatefulWidget {
  const _GuestLogin();

  @override
  ConsumerState<_GuestLogin> createState() => _GuestLoginState();
}

class _GuestLoginState extends ConsumerState<_GuestLogin> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authProvider.notifier).signInWithKakao();
      // 성공하면 이 카드는 곧 사라진다. 취소면 조용히 다시 누를 수 있게 둔다.
      if (mounted) setState(() => _busy = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyLoginCard(
      busy: _busy,
      errorText: _error,
      onLogin: () => unawaited(_signIn()),
    );
  }
}

/// 내가 등록한 사건. 진행 중과 지난 사건을 나눠 적는다.
///
/// 지난 사건을 아래로 내리되 지우지는 않는다(설계 결정 7번). 대신 몇 건만
/// 펼쳐 두고 접는다.
///
/// **진행 중인 사건은 접지 않는다.** 안 보이면 발견 완료를 누를 수 없고,
/// 한 사람이 동시에 등록하는 사건은 한두 건이다.
class _MyCases extends ConsumerWidget {
  const _MyCases();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(myCasesProvider).value;
    if (cases == null || cases.items.isEmpty) return const SizedBox.shrink();

    final active = cases.items
        .where((item) => item.status == CaseStatus.active)
        .toList(growable: false);
    final resolved = cases.items
        .where((item) => item.status != CaseStatus.active)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty) ...[
          MySectionHeader(
            title: '내가 등록한 실종자',
            trailing: '${active.length}건 진행 중',
          ),
          for (final item in active)
            MyCaseCard(
              summary: item,
              // 상세가 곧 사건 관리 화면이다. 정보 수정·사진 추가·제보 관리가 거기 있다.
              onTap: () => _openCase(context, item.id),
              onResolve: () => unawaited(_confirmResolve(context, ref, item)),
            ),
        ],
        if (resolved.isNotEmpty) ...[
          MySectionHeader(title: '지난 사건', trailing: '${resolved.length}건'),
          MyFoldedList(
            collapsedCount: MyScreen.pastCasesPreview,
            children: [
              for (final item in resolved)
                MyCaseCard(
                  summary: item,
                  onTap: () => _openCase(context, item.id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// 발견 완료는 되돌리기 어렵다. 한 번 묻는다([ResolveCaseDialog]).
  Future<void> _confirmResolve(
    BuildContext context,
    WidgetRef ref,
    MissingCaseSummary summary,
  ) async {
    if (!await ResolveCaseDialog.show(context, name: summary.name)) return;

    await ref.read(myRepositoryProvider).resolveCase(summary.id);
    // 사건 목록과 건수가 함께 바뀐다. 홈·실종자 목록·지도·상세도 다시 받는다 —
    // 안 받으면 방금 찾은 사람이 홈에 진행 중으로 남는다.
    ref
      ..invalidate(myCasesProvider)
      ..invalidate(myProfileProvider)
      ..invalidate(homeFeedProvider)
      ..invalidate(missingListProvider)
      ..invalidate(mapCasesProvider)
      ..invalidate(missingDetailProvider(summary.id));
  }
}

/// 제보 이력 목록. 불러오는 중·실패·빈 상태를 모두 이 자리에서 처리한다.
class _MyReports extends ConsumerWidget {
  const _MyReports({required this.reports});

  final AsyncValue<MyReportList> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return reports.when(
      loading: () => const SizedBox(height: 120, child: LoadingView()),
      error: (error, stackTrace) => ErrorView(
        message: error is ApiException ? error.message : '제보 이력을 불러오지 못했어요.',
        onRetry: () => ref.invalidate(myReportsProvider),
      ),
      data: (data) => data.isEmpty
          ? const _Empty()
          : MyFoldedList(
              collapsedCount: MyScreen.reportsPreview,
              children: [
                for (final report in data.items)
                  MyReportTile(
                    report: report,
                    // 내 제보가 경로 어디에 놓였는지, 그 사람을 찾았는지 본다.
                    onTap: switch (report.missingId) {
                      final caseId? => () => _openCase(context, caseId),
                      null => null,
                    },
                  ),
              ],
            ),
    );
  }
}

/// 사건 상세(S3)를 MY 위에 쌓는다. 돌아오면 MY가 그대로 있다.
void _openCase(BuildContext context, String caseId) {
  unawaited(context.push(AppRoute.missingDetail(caseId)));
}

/// 아직 제보한 적이 없다.
///
/// 실패가 아니라 아직 안 한 것이라, 다그치지 않고 무엇을 하면 되는지만 적는다.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Text(
        '아직 보낸 제보가 없어요.\n지나가다 본 얼굴을 한 장만 올려주시면 됩니다.',
        textAlign: TextAlign.center,
        style: AppTextStyles.body0.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}
