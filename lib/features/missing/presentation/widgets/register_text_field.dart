import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form_field_label.dart';
import 'register_error_text.dart';

/// 등록 폼의 글자 입력칸 하나. 이름 · 나이 · 인상착의 · 주소 · 키·몸무게.
///
/// **값은 바깥이 쥔다.** 입력칸이 제 컨트롤러에 값을 따로 들고 있으면,
/// 임시저장을 되살린 값이 칸에 반영되지 않는다.
/// 그래서 바깥에서 들어온 [value]가 칸의 글자와 다를 때만 갈아끼운다.
class RegisterTextField extends StatefulWidget {
  const RegisterTextField({
    required this.fieldKey,
    required this.value,
    required this.onChanged,
    this.label,
    this.required = false,
    this.hint,
    this.help,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.suffixText,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
    super.key,
  });

  /// 테스트가 입력칸을 찾는 키. 칸 자체에 붙는다.
  final Key fieldKey;

  final String value;
  final ValueChanged<String> onChanged;

  /// 칸 위의 항목 이름. 두 칸을 한 줄에 둘 때 바깥이 따로 그리면 null.
  final String? label;
  final bool required;

  final String? hint;

  /// 칸 아래의 회색 도움말. 오류가 있으면 오류가 대신한다.
  final String? help;

  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffixText;
  final int maxLines;
  final TextInputAction textInputAction;

  @override
  State<RegisterTextField> createState() => _RegisterTextFieldState();
}

class _RegisterTextFieldState extends State<RegisterTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant RegisterTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value == _controller.text) return;

    // 바깥에서 값이 바뀌었다(되살림, 하이픈). 커서는 끝으로 보낸다.
    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final help = widget.help;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          FormFieldLabel(label, required: widget.required),
          const SizedBox(height: 8),
        ],
        TextField(
          key: widget.fieldKey,
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textInputAction: widget.maxLines > 1
              ? TextInputAction.newline
              : widget.textInputAction,
          minLines: widget.maxLines > 1 ? 3 : 1,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixText: widget.suffixText,
          ),
        ),
        // 오류는 InputDecoration.errorText로 그리지 않는다. 그쪽은 칸 안쪽으로
        // 들여 그려져서, 왼쪽에 붙은 도움말이나 사진·구분 칸의 안내와 줄이
        // 어긋난다.
        if (widget.errorText != null)
          RegisterErrorText(widget.errorText)
        else if (help != null) ...[
          const SizedBox(height: 7),
          Text(
            help,
            style: AppTextStyles.body0.copyWith(
              color: AppColors.textDisabled,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}
