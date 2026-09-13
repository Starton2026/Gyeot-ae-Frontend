import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// "계속 쓰기". 눌러도 화면에 남는다.
const Key reportExitKeepKey = Key('report_exit_keep');

/// "나가기". 사진과 분석 결과를 버리고 나간다.
const Key reportExitLeaveKey = Key('report_exit_leave');

/// 이탈 방지(F-4.7). 나가면 사진과 분석 결과가 사라진다고 한 번 묻는다.
///
/// 되묻는 이유는 되돌릴 수 없어서다. 카메라로 방금 찍은 사진은 앨범에 남지
/// 않는 경우가 있고, 그 사람은 이미 그 자리를 떠났다.
///
/// 나가겠다고 하면 true.
Future<bool> confirmLeaveReport(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('작성을 취소할까요?'),
      content: const Text('올린 사진과 분석 결과가 사라집니다.'),
      actions: [
        TextButton(
          key: reportExitKeepKey,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('계속 쓰기'),
        ),
        TextButton(
          key: reportExitLeaveKey,
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('나가기'),
        ),
      ],
    ),
  );

  return leave ?? false;
}
