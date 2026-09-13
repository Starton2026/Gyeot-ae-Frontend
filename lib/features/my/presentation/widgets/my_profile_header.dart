import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/missing_thumbnail.dart';

/// 로그인 MY의 프로필 줄.
///
/// 카카오에서 받는 것은 닉네임과 프로필 사진뿐이라(F-6.3) 담을 것도 그것뿐이다.
/// 대신 **내가 이 서비스에 무엇을 했는지**를 건수로 옆에 적는다. 계정이
/// 이름표가 아니라 기록이 되어야 다시 들어올 이유가 생긴다.
class MyProfileHeader extends StatelessWidget {
  const MyProfileHeader({
    required this.name,
    required this.caseCount,
    required this.reportCount,
    this.photoUrl,
    super.key,
  });

  final String name;

  /// 내가 보호자로 등록한 사건 수.
  final int caseCount;

  /// 내가 보낸 제보 수.
  final int reportCount;

  /// 카카오 프로필 사진. 없을 수 있다.
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
      child: Row(
        children: [
          // 사람 사진을 둥글게 자르는 일은 실종자 썸네일과 같다. 사진이
          // 없을 때 실루엣을 그리는 것도 같아서 그대로 쓴다.
          MissingThumbnail(
            photoPath: photoUrl,
            width: 52,
            height: 52,
            radius: 26,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.title0),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const _KakaoChip(),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '등록 사건 $caseCount · 제보 $reportCount',
                        style: AppTextStyles.body0.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 어떻게 로그인했는지. 지금은 카카오 하나뿐이다(F-6.2).
class _KakaoChip extends StatelessWidget {
  const _KakaoChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.kakaoYellow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          'kakao',
          style: AppTextStyles.small.copyWith(color: AppColors.kakaoLabel),
        ),
      ),
    );
  }
}
