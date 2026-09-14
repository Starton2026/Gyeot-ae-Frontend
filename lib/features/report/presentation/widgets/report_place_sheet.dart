import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 자세한 위치를 덧붙이는 시트(F-4.3).
///
/// **좌표를 옮기는 것이 아니라 그 위에 이름을 얹는 것이다.** "만수주공 앞
/// 버스정류장"처럼 주소로는 안 잡히는 말이 보호자에게는 가장 빠른 단서다.
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
              const Text('자세한 위치 더하기', style: AppTextStyles.title0),
              const SizedBox(height: 6),
              Text(
                '지금 위치에 덧붙여 적습니다. 건물 이름이나 눈에 띄는 곳이면 돼요. '
                '비워두셔도 됩니다.',
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
                  hintText: '예) 인하공전 도서관 앞',
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
