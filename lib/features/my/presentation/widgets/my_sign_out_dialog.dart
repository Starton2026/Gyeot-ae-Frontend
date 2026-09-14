import 'package:flutter/material.dart';

/// 로그아웃 확인 창. 확인하면 true를 돌려준다.
///
/// 되돌리기 어려운 동작은 아니지만 **이 폰으로 내 사건의 제보 알림이 끊긴다.**
/// 보호자가 그 사실을 모르고 누르면, 아이를 봤다는 제보가 와도 폰이 조용하다.
/// 그래서 한 번 묻고, 무엇이 남고 무엇이 끊기는지 적는다.
class MySignOutDialog extends StatelessWidget {
  const MySignOutDialog({super.key});

  static const Key confirmKey = Key('my_sign_out_confirm');

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const MySignOutDialog(),
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('로그아웃할까요?'),
      content: const Text(
        // 줄마다 폭 안에 들어가게 끊었다. 길게 두면 한글이 단어 중간에서 넘어간다.
        '등록한 사건과 제보 이력은 계정에 남아요.\n'
        '다만 이 폰으로는 제보 알림이 오지 않아요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        // FilledButton을 쓰지 않는다. 테마가 가로를 꽉 채우는 최소 크기를 줘서
        // 대화상자 버튼 줄에 나란히 서지 못한다.
        TextButton(
          key: confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('로그아웃'),
        ),
      ],
    );
  }
}
