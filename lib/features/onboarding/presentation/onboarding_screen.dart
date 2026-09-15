import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/current_location.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/mascot.dart';
import 'widgets/match_illustration.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/permission_list.dart';
import 'widgets/route_illustration.dart';

/// 온보딩(S0). 첫 실행에 한 번만 본다.
///
/// 세 장의 순서에 이유가 있다. 무엇을 하는 앱인지(1) → 틀려도 괜찮다는
/// 안심(2) → 그래서 위치를 달라는 부탁(3). 부탁을 맨 뒤에 두어야 앞의 두
/// 장이 그 부탁의 근거가 된다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const Key skipButtonKey = Key('onboarding_skip');

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _pageCount = 3;
  static const Duration _slide = Duration(milliseconds: 280);

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(duration: _slide, curve: Curves.easeOut);
  }

  /// 온보딩을 끝내고 홈으로. 건너뛰어도 본 것으로 친다.
  ///
  /// [askLocation]이면 시스템 권한 팝업을 띄운다. 거부해도 그대로 홈으로
  /// 간다. 위치 없이도 앱은 돈다(CLAUDE.md 규칙).
  Future<void> _finish({bool askLocation = false}) async {
    if (askLocation) {
      await ref
          .read(currentLocationProvider.notifier)
          .locate(requestPermission: true);
    }

    await ref.read(onboardingStorageProvider).markSeen();

    if (!mounted) return;
    context.go(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: TextButton(
                  key: OnboardingScreen.skipButtonKey,
                  // 마지막 장은 건너뛸 수 없다. 건너뛰기와 "나중에 할게요"가
                  // 같은 자리에서 같은 일을 하면 무엇을 눌러야 할지 헷갈린다.
                  onPressed: _page == _pageCount - 1 ? null : _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textDisabled,
                    disabledForegroundColor: Colors.transparent,
                  ),
                  child: const Text('건너뛰기'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [_FirstPage(), _SecondPage(), _ThirdPage()],
              ),
            ),
            OnboardingFooter(
              pageCount: _pageCount,
              page: _page,
              onNext: _next,
              onAllowLocation: () => _finish(askLocation: true),
              onLater: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

/// 무엇을 하는 앱인가. 차별점을 맨 앞에 둔다.
class _FirstPage extends StatelessWidget {
  const _FirstPage();

  @override
  Widget build(BuildContext context) {
    return const OnboardingPage(
      art: RouteIllustration(),
      title: '흩어진 목격이\n하나의 길이 됩니다',
      body: Text(
        '시민이 올린 제보를 시간순으로 이어 사라진 사람이 어디로 갔는지 '
        '복원합니다. 제보 하나는 단편이지만, 모이면 방향이 보입니다.',
      ),
    );
  }
}

/// 망설이는 이유를 먼저 덜어준다.
class _SecondPage extends StatelessWidget {
  const _SecondPage();

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      art: const MatchIllustration(),
      title: '확신이 없어도\n괜찮습니다',
      body: Text.rich(
        TextSpan(
          text: 'AI가 등록 사진과 얼굴을 대조해 유사도를 알려드립니다. '
              '닮은 것 같다면 일단 알려주세요. ',
          children: [
            TextSpan(
              text: '확인은 보호자가 합니다.',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 앞의 두 장을 근거로 위치를 부탁한다.
class _ThirdPage extends StatelessWidget {
  const _ThirdPage();

  @override
  Widget build(BuildContext context) {
    return const OnboardingPage(
      art: Mascot(MascotPose.connect, height: 200),
      title: '내 주변 사건을\n알려드릴게요',
      body: Text('위치는 아래 두 가지에만 씁니다.'),
      extra: PermissionList(),
    );
  }
}
