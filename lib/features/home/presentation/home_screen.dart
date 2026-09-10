import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

/// 앱의 첫 화면. 로그인 없이 바로 볼 수 있다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Key loginButtonKey = Key('home_login_button');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('곁애')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('곁에 있다 + 사랑', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('여기에 홈 화면 콘텐츠를 채워주세요.', style: textTheme.bodyMedium),
              const Spacer(),
              OutlinedButton(
                key: loginButtonKey,
                onPressed: () => context.push(AppRoute.login),
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
