import 'package:flutter/material.dart';

/// 선택 로그인 화면.
///
/// 로그인 방식(FastAPI 이메일 로그인 / Firebase Auth)이 정해지면
/// `features/auth/data/`에 API·리포지토리를 추가하고 여기서 호출한다.
/// 네트워크 호출 패턴은 README의 "기능 추가하는 법"을 참고.
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
                // TODO(auth): 로그인 방식이 정해지면 연결하기
                onPressed: null,
                child: Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
