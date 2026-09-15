import 'package:flutter/material.dart';

/// 발견 완료 확인 창. 확인하면 true를 돌려준다.
///
/// MY(S8)의 내 사건 카드와 실종자 상세(S3)의 보호자 메뉴가 같은 창을 띄운다.
///
/// 찾았다는 것은 이 서비스에서 가장 좋은 소식이지만, 되돌리기 어렵다. 잘못
/// 누르면 사건이 목록 아래로 내려가고 제보자들에게 결과 알림이 나간다. 그래서
/// 한 번 묻는다.
class ResolveCaseDialog extends StatelessWidget {
  const ResolveCaseDialog({required this.name, super.key});

  /// 찾은 사람의 이름.
  final String name;

  static const Key confirmKey = Key('resolve_case_confirm');

  static Future<bool> show(BuildContext context, {required String name}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResolveCaseDialog(name: name),
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$name 님을 찾으셨나요?'),
      content: const Text('제보해 주신 분들에게 결과를 알려드립니다.\n사건은 목록에 그대로 남습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('아니요'),
        ),
        // FilledButton을 쓰지 않는다. 테마가 가로를 꽉 채우는 최소 크기를 줘서
        // 대화상자 버튼 줄에 나란히 서지 못하고 아니요를 위로 밀어낸다.
        TextButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('발견 완료'),
        ),
      ],
    );
  }
}
