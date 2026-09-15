import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 바텀시트 맨 위의 손잡이 막대.
///
/// 끌어내릴 수 있다는 표시다. 시트마다 다시 그리면 두께와 여백이 조금씩
/// 어긋나서, 시트를 두 개 이상 쓰게 된 시점에 여기로 모았다.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
