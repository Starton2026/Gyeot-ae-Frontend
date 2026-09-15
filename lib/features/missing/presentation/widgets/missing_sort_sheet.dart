import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/missing_case.dart';
import '../missing_list_providers.dart';

/// 정렬 기준을 고르는 바텀시트(F-2.3).
///
/// 고른 값을 돌려준다. 닫기만 하면 null이다.
Future<MissingSort?> showMissingSortSheet(
  BuildContext context, {
  required MissingSort current,
}) {
  return showModalBottomSheet<MissingSort>(
    context: context,
    backgroundColor: AppColors.background,
    builder: (context) => _MissingSortSheet(current: current),
  );
}

class _MissingSortSheet extends StatelessWidget {
  const _MissingSortSheet({required this.current});

  final MissingSort current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('정렬', style: AppTextStyles.title0),
          ),
          for (final sort in MissingSort.values)
            ListTile(
              title: Text(
                sort.label,
                style: AppTextStyles.subtitle1.copyWith(
                  color: sort == current
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              trailing: sort == current
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(sort),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
