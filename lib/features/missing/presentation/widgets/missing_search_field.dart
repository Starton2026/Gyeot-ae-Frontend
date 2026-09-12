import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icon.dart';

/// 이름·지역 검색창(F-2.1).
///
/// 글자를 칠 때마다 목록을 부르면 한 글자에 한 번씩 요청이 나간다. 마지막
/// 입력에서 [_debounce]만큼 멈췄을 때 한 번만 알린다.
class MissingSearchField extends StatefulWidget {
  const MissingSearchField({required this.onChanged, super.key});

  final ValueChanged<String> onChanged;

  static const Key fieldKey = Key('missing_search_field');

  @override
  State<MissingSearchField> createState() => _MissingSearchFieldState();
}

class _MissingSearchFieldState extends State<MissingSearchField> {
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: MissingSearchField.fieldKey,
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      onSubmitted: widget.onChanged,
      decoration: InputDecoration(
        hintText: '이름 · 지역으로 찾기',
        // 테마 기본 여백은 한 화면에 검색·칩·정렬이 함께 있는 이 화면에서
        // 너무 두껍다. 모양(채움·모서리)은 테마 것을 그대로 쓴다.
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 9),
          child: AppIcon(
            AppIcons.glass,
            size: 17,
            color: AppColors.textDisabled,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, child) {
            if (value.text.isEmpty) return const SizedBox.shrink();

            return IconButton(
              onPressed: _clear,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textDisabled,
              tooltip: '지우기',
            );
          },
        ),
      ),
    );
  }
}
