import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../../data/auth_session.dart';
import '../auth_providers.dart';

/// 로그인(S6)을 띄운다. 성공하면 세션을, 닫거나 취소하면 null을 돌려준다.
///
/// **독립 화면이 아니라 끼어드는 시트다**(기능정의서 3). 등록을 시도할 때
/// 그 위에 덮이고, 성공하면 시트만 걷히고 하던 일이 이어진다(F-6.4).
/// 홈으로 되돌리지 않는다.
Future<AuthSession?> showLoginSheet(BuildContext context) {
  return showModalBottomSheet<AuthSession>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    // 분석 시트와 같은 막. 검정으로 덮으면 뒤 화면이 죽어 보인다.
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => const LoginSheet(),
  );
}

/// 카카오 하나뿐인 로그인 시트(S6).
///
/// **선택지가 하나면 화면은 단순해지는 대신 "왜 로그인해야 하는가"를 더
/// 분명히 말해야 한다.** 그래서 위에는 요구하는 이유를, 아래에는 로그인
/// 없이도 제보할 수 있다는 말을 둔다. 아래 문구가 빠지면 카카오 계정이 없는
/// 사람이 서비스 전체를 못 쓴다고 오해한다.
class LoginSheet extends ConsumerStatefulWidget {
  const LoginSheet({super.key});

  static const Key kakaoButtonKey = Key('login_kakao');

  @override
  ConsumerState<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<LoginSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final session = await ref.read(authProvider.notifier).signInWithKakao();

      if (!mounted) return;
      // 취소면 시트를 열어둔 채로 둔다. 다시 누를 수 있어야 한다.
      if (session == null) {
        setState(() => _busy = false);
        return;
      }

      Navigator.of(context).pop(session);
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
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const _WhyCard(),
              const SizedBox(height: 18),
              // 제목을 따로 두지 않는다. 버튼에 "카카오로 시작하기"가 이미
              // 적혀 있어서 바로 위에 같은 말을 또 쓰면 읽는 사람이 두 번
              // 읽는다. 그 자리를 이음이에게 준다.
              const Center(child: Mascot(MascotPose.run, height: 140)),
              const SizedBox(height: 14),
              // 제목을 뺀 자리에서 이 문장이 제목 노릇을 한다. 로그인을
              // 망설이는 이유가 대개 "귀찮아서"라, 얼마나 안 걸리는지를 먼저
              // 눈에 띄게 둔다.
              Text.rich(
                TextSpan(
                  text: '3초면 끝납니다.\n',
                  style: AppTextStyles.subtitle0.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(
                      text: '새 비밀번호를 만들 필요가 없습니다.',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              _KakaoButton(busy: _busy, onPressed: _signIn),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body0.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                '계속하면 서비스 이용약관과 개인정보 처리방침에\n동의하는 것으로 봅니다',
                textAlign: TextAlign.center,
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textDisabled,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const _GuestNote(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 왜 로그인을 요구하는지(F-6.1). 시트에서 가장 위에 온다.
///
/// 로그인을 요구받는 사람이 가장 먼저 묻는 것이 "왜"다. 이유를 안 적으면
/// 계정을 모으려는 것으로 읽힌다.
class _WhyCard extends StatelessWidget {
  const _WhyCard();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body0.copyWith(
      color: AppColors.textCareAccent,
      height: 1.55,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.textCareAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '허위 등록을 막기 위해 ',
                  style: style.copyWith(fontWeight: FontWeight.w700),
                  children: [
                    TextSpan(
                      text: '보호자 확인이 필요합니다. '
                          '실종자 등록에만 요구되며, 다른 기능에는 쓰이지 않습니다.',
                      style: style,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카카오가 정한 모양 그대로. 색과 비율을 바꾸지 않는다.
class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: LoginSheet.kakaoButtonKey,
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.kakaoYellow,
        foregroundColor: AppColors.kakaoLabel,
        disabledBackgroundColor: AppColors.kakaoYellow,
        disabledForegroundColor: AppColors.kakaoLabel,
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.kakaoLabel,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(AppIcons.kakao, size: 19),
                SizedBox(width: 8),
                Text('카카오로 시작하기'),
              ],
            ),
    );
  }
}

/// 닫아도 괜찮다는 말. **이 시트에서 빼면 안 되는 문장이다.**
class _GuestNote extends StatelessWidget {
  const _GuestNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Text.rich(
        TextSpan(
          text: '제보는 로그인 없이도 할 수 있어요.\n',
          style: AppTextStyles.body0.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: '지금 닫아도 목격 제보는 그대로 가능합니다.',
              style: AppTextStyles.body0.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
