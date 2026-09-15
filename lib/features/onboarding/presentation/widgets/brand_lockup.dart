import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 세로 조합 락업. 마크를 위에 두고 워드마크를 아래에 둔다.
///
/// 상단바가 없는 스플래시에서만 쓴다. 공간이 넉넉해 브랜드가 화면 전체를
/// 쓸 수 있는 유일한 화면이다(5.6).
///
/// **여기서는 `곁愛`를 쓴다**(설계 결정 10번). 본문·푸시·작은 글씨에는
/// 화면 낭독기 때문에 `곁애`를 쓰지만, 로고 자리는 한자 쪽이다. 낭독기에는
/// [Semantics]로 `곁애`를 따로 준다.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  /// 마크 높이.
  static const double _markHeight = 104;

  static final TextStyle _hanja = AppTextStyles.hanja.copyWith(
    color: AppColors.accent,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_icon.png',
          height: _markHeight,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: '곁',
                style: TextStyle(color: AppColors.primary),
              ),
              // Pretendard에 없는 글자라 전용 글꼴을 물린다.
              TextSpan(text: '愛', style: _hanja),
            ],
          ),
          semanticsLabel: '곁애',
          style: AppTextStyles.wordmark,
        ),
      ],
    );
  }
}
