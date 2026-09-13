import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../missing/data/missing_case.dart';
import '../data/my_report.dart';
import '../data/my_repository.dart';
import 'my_providers.dart';
import 'widgets/my_case_card.dart';
import 'widgets/my_device_note.dart';
import 'widgets/my_login_card.dart';
import 'widgets/my_menu.dart';
import 'widgets/my_profile_header.dart';
import 'widgets/my_report_tile.dart';
import 'widgets/my_section_header.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final profile = ref.watch(myProfileProvider).value;
    final reports = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: const AppTopBar.title('MY'),
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
          MyMenu(signedIn: user != null),
        ],
      ),
    );
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
/// 지난 사건을 아래로 내리되 지우지는 않는다(설계 결정 7번).
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
              onResolve: () => unawaited(_confirmResolve(context, ref, item)),
            ),
        ],
        if (resolved.isNotEmpty) ...[
          MySectionHeader(title: '지난 사건', trailing: '${resolved.length}건'),
          for (final item in resolved) MyCaseCard(summary: item),
        ],
      ],
    );
  }

  /// 발견 완료는 되돌리기 어렵다. 한 번 묻는다.
  ///
  /// 찾았다는 것은 이 서비스에서 가장 좋은 소식이지만, 잘못 누르면 사건이
  /// 목록 아래로 내려가고 제보자들에게 결과 알림이 나간다.
  Future<void> _confirmResolve(
    BuildContext context,
    WidgetRef ref,
    MissingCaseSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${summary.name} 님을 찾으셨나요?'),
        content: const Text('제보해 주신 분들에게 결과를 알려드립니다.\n사건은 목록에 그대로 남습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니요'),
          ),
          FilledButton(
            key: const Key('my_case_resolve_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('발견 완료'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(myRepositoryProvider).resolveCase(summary.id);
    // 사건 목록과 건수가 함께 바뀐다.
    ref
      ..invalidate(myCasesProvider)
      ..invalidate(myProfileProvider);
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
          : Column(
              children: [
                for (final report in data.items) MyReportTile(report: report),
              ],
            ),
    );
  }
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
