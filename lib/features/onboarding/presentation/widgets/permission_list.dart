import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 위치를 무엇에 쓰는지, 그리고 **무엇에 쓰지 않는지**(온보딩 3장).
///
/// 시스템 권한 팝업 바로 앞에서 이유를 먼저 말한다. 한 번 거부하면 되돌리기
/// 어렵고, 앱 안에서는 다시 물어볼 방법이 없다. 쓰지 않는 것까지 적는 이유는
/// 거부하는 사람이 가장 걱정하는 것이 "평소에도 따라다니는가"이기 때문이다.
class PermissionList extends StatelessWidget {
  const PermissionList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PermissionRow(text: '내 주변에서 발생한 사건 알림'),
        SizedBox(height: 10),
        _PermissionRow(text: '제보할 때 목격 위치 자동 기록'),
        SizedBox(height: 10),
        _PermissionRow(text: '평소 위치를 저장하거나 추적하지 않습니다', used: false),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.text, this.used = true});

  final String text;

  /// false면 "이건 안 합니다" 줄이다.
  final bool used;

  @override
  Widget build(BuildContext context) {
    final color = used ? AppColors.textSecondary : AppColors.textDisabled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            used ? Icons.check_rounded : Icons.close_rounded,
            size: 16,
            color: used ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.subtitle1.copyWith(color: color, height: 1.5),
          ),
        ),
      ],
    );
  }
}
