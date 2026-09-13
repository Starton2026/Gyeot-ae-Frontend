import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/storage/onboarding_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/mascot.dart';
import 'widgets/brand_lockup.dart';

/// 브랜드를 적어도 이만큼은 보여준다.
///
/// 저장소를 읽는 시간은 기기마다 들쭉날쭉해서, 그대로 두면 어떤 기기에서는
/// 스플래시가 깜빡이고 끝난다. 읽기와 **함께** 기다려서 둘 중 늦은 쪽을
/// 기준으로 넘어간다.
///
/// 테스트에서는 0으로 덮어 기다리지 않는다.
final splashHoldProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 1200);
});

/// 스플래시(S0). 첫 실행이면 온보딩으로, 아니면 곧장 홈으로 보낸다.
///
/// 기능정의서는 온보딩을 **첫 실행 1회**로 정한다. 그 판단을 여기서 하고,
/// 판단이 끝날 때까지 브랜드를 보여준다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    final results = await Future.wait([
      ref.read(onboardingStorageProvider).seen(),
      Future<void>.delayed(ref.read(splashHoldProvider)),
    ]);

    if (!mounted) return;

    final seen = results.first as bool;
    context.go(seen ? AppRoute.home : AppRoute.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundSubtle, AppColors.brandHope],
          ),
        ),
        child: SafeArea(
          // Column은 가로를 자식 폭에 맞춰 줄인다. 화면 전체를 쓰라고
          // 못 박아야 가운데 정렬이 화면 기준이 된다.
          child: SizedBox.expand(
            // 가운데 정렬이 아니라 위에서부터 쌓는다. 마크와 이름이 위에
            // 자리를 잡아야 아래가 이음이 몫으로 남는다.
            child: Column(
              children: [
                const SizedBox(height: 48),
                const BrandLockup(),
                const SizedBox(height: 34),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _Slogan(),
                ),
                // 남는 자리를 이음이가 다 쓰되, 짧은 화면에서는 줄어든다.
                // 고정 높이로 두면 세로가 모자란 기기에서 넘친다.
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: Mascot(MascotPose.basic, height: 258),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '사람을 찾는, 가장 따뜻한 연결',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body0.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 첫 줄은 이 서비스가 무엇을 되돌리려는지, 둘째 줄은 그게 누구 덕인지.
///
/// 둘째 줄은 제보 완료 화면(F-4.2.4)에 적는 브랜드 문장과 같은 말이다.
/// 처음 켰을 때 한 번 읽고, 실제로 제보를 마쳤을 때 다시 만난다.
class _Slogan extends StatelessWidget {
  const _Slogan();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          const TextSpan(
            text: '사라진 ',
            children: [
              TextSpan(
                text: '오늘',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: '을, 다시 '),
              TextSpan(
                text: '함께',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.tagline.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          '작은 관심이 누군가의\n내일이 됩니다.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
