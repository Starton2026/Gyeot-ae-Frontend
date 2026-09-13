import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 장소 이름을 적는 시트(F-4.3의 수동 조정).
///
/// 좌표는 그대로 두고 **이름만** 받는다. "만수주공 앞 버스정류장"처럼 주소로는
/// 안 잡히는 말이 보호자에게는 가장 빠른 단서다.
///
/// 제보창 본문에 입력란을 두지 않고 여기로 뺀 이유는, 적고 싶은 사람만
/// 적으면 되기 때문이다. 본문에 빈 칸이 하나 늘면 그만큼 제보가 준다.
Future<String?> showReportPlaceSheet(
  BuildContext context, {
  required String initial,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (context) => _ReportPlaceSheet(initial: initial),
  );
}

class _ReportPlaceSheet extends StatefulWidget {
  const _ReportPlaceSheet({required this.initial});

  final String initial;

  @override
  State<_ReportPlaceSheet> createState() => _ReportPlaceSheetState();
}

class _ReportPlaceSheetState extends State<_ReportPlaceSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('어디에서 보셨나요?', style: AppTextStyles.title0),
              const SizedBox(height: 6),
              Text(
                '건물 이름이나 눈에 띄는 곳을 적어주세요. 비워두셔도 됩니다.',
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirm(),
                decoration: const InputDecoration(
                  hintText: '만수주공 앞 버스정류장',
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _confirm,
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
