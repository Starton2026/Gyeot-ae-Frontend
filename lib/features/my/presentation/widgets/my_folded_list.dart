import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// MY의 목록을 몇 건만 펼쳐 두고 나머지는 접어 두는 자리.
///
/// **MY는 이력이 쌓이는 화면이라 그냥 두면 끝없이 길어진다.** 제보를 백 번
/// 하면 백 줄이 되고, 아래에 있는 설정 메뉴는 아무도 못 찾는다. 그렇다고
/// 서버에서 잘라 오면 "내 제보 12건"이라 적어 놓고 5건만 주는 셈이라 건수가
/// 거짓이 된다. 그래서 **전부 받아서 접어 둔다.**
///
/// 별도 화면으로 보내지 않는 것은, 목록 하나 보자고 화면을 옮기면 돌아올 때
/// 스크롤 위치를 잃기 때문이다.
class MyFoldedList extends StatefulWidget {
  const MyFoldedList({
    required this.children,
    required this.collapsedCount,
    super.key,
  });

  final List<Widget> children;

  /// 접어 둔 상태에서 보여줄 개수.
  final int collapsedCount;

  static const Key expandKey = Key('my_folded_expand');

  @override
  State<MyFoldedList> createState() => _MyFoldedListState();
}

class _MyFoldedListState extends State<MyFoldedList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hidden = widget.children.length - widget.collapsedCount;
    // 한두 건 더 있다고 버튼을 내밀 필요는 없다. 접어서 아끼는 높이보다
    // 버튼 높이가 더 크다.
    if (hidden <= 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...(_expanded
            ? widget.children
            : widget.children.take(widget.collapsedCount)),
        _FoldToggle(
          hidden: hidden,
          expanded: _expanded,
          onTap: () => setState(() => _expanded = !_expanded),
        ),
      ],
    );
  }
}

/// 펼치고 접는 줄. 몇 건이 숨어 있는지 숫자로 말한다.
class _FoldToggle extends StatelessWidget {
  const _FoldToggle({
    required this.hidden,
    required this.expanded,
    required this.onTap,
  });

  final int hidden;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: MyFoldedList.expandKey,
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: AppTextStyles.body1,
        foregroundColor: AppColors.textSecondary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(expanded ? '접기' : '$hidden건 더 보기'),
          const SizedBox(width: 2),
          Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 18,
          ),
        ],
      ),
    );
  }
}
