import 'package:flutter/material.dart';

/// 로딩 중일 때 화면 가운데에 놓는 위젯.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
