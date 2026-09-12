import 'package:flutter/material.dart';

/// 선택 로그인 화면(S6).
///
/// **로그인 방식은 카카오 하나로 정해졌다**(API 명세서 3절). 가입과 로그인을
/// 구분하지 않고, 카카오에서 받는 정보는 닉네임과 프로필 이미지뿐이다.
/// 보호자 연락처는 계정이 아니라 등록 폼에서 받는다(F-7.10).
///
/// TODO(auth): 카카오 SDK로 받은 `access_token`을 `POST /auth/kakao`에 넘기는
/// 리포지토리를 `features/auth/data/`에 추가하고 여기서 호출한다.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                '로그인 없이도 앱을 쓸 수 있어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const FilledButton(
                // TODO(auth): 카카오 SDK를 붙이면 연결한다.
                onPressed: null,
                child: Text('카카오로 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
