import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "계속 쓰기". 눌러도 화면에 남는다.
const Key registerExitKeepKey = Key('register_exit_keep');

/// "임시저장하고 나가기".
const Key registerExitSaveKey = Key('register_exit_save');

/// "나가기". 쓴 것을 버리고 나간다.
const Key registerExitLeaveKey = Key('register_exit_leave');

/// 등록 폼을 닫을 때 어떻게 할지.
enum RegisterExitChoice { keep, save, leave }

/// 쓰던 내용이 있을 때 닫기 전에 한 번 묻는다.
///
/// 보호자는 사진을 고르다 전화를 받고 나가는 일이 흔하다. 그냥 버리지 않고
/// 임시저장하고 나갈 길을 함께 준다.
Future<RegisterExitChoice> confirmLeaveRegister(BuildContext context) async {
  final choice = await showDialog<RegisterExitChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('등록을 그만할까요?'),
      content: const Text('임시저장하면 다음에 이어서 쓸 수 있습니다.'),
      actions: [
        TextButton(
          key: registerExitKeepKey,
          onPressed: () => Navigator.of(context).pop(RegisterExitChoice.keep),
          child: const Text('계속 쓰기'),
        ),
        TextButton(
          key: registerExitLeaveKey,
          onPressed: () => Navigator.of(context).pop(RegisterExitChoice.leave),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('나가기'),
        ),
        TextButton(
          key: registerExitSaveKey,
          onPressed: () => Navigator.of(context).pop(RegisterExitChoice.save),
          child: const Text('임시저장하고 나가기'),
        ),
      ],
    ),
  );

  return choice ?? RegisterExitChoice.keep;
}
