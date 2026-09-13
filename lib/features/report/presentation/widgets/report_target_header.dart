import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';

/// 누구를 제보하는지 못 박는 머리글(F-4.1).
///
/// 목록에서 여러 사건을 훑다가 들어오면 누구를 신고하는 중인지 흐려진다.
/// 사진과 이름을 화면 맨 위에 붙여두면, 다른 사람을 찍어 올리는 일이 줄어든다.
class ReportTargetHeader extends StatelessWidget {
  const ReportTargetHeader({
    required this.name,
    required this.ageGenderLabel,
    required this.description,
    this.thumbnail,
    super.key,
  });

  final String name;

  /// `7세 남아`.
  final String ageGenderLabel;

  /// 인상착의 한 줄.
  final String description;

  final String? thumbnail;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandHope,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        child: Row(
          children: [
            MissingThumbnail(
              photoPath: thumbnail,
              width: 40,
              height: 48,
              radius: 10,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name · $ageGenderLabel',
                    style: AppTextStyles.subtitle0.copyWith(
                      color: AppColors.textCareAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.body0.copyWith(
                      color: AppColors.textCareAccent.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
