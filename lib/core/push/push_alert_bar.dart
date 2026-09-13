import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'push_messaging.dart';

/// 앱을 켜 둔 사람에게 알림을 띄운다.
///
/// 안드로이드는 앱이 앞에 있으면 알림을 그려주지 않는다. 그대로 두면 제보하려고
/// 앱을 열어 둔 사람만 주변 소식을 못 받는다.
///
/// **마스코트를 쓰지 않는다**(설계 결정 8번). 실종 신고를 알리는 자리다.
SnackBar pushAlertBar({required PushAlert alert, VoidCallback? onOpen}) {
  return SnackBar(
    key: pushAlertBarKey,
    backgroundColor: AppColors.textPrimary,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    // 긴급한 소식이라 기본 4초보다 길게 둔다. 읽고 누를 시간이 필요하다.
    duration: const Duration(seconds: 8),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          alert.title,
          style: AppTextStyles.subtitle0.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 3),
        Text(
          alert.body,
          style: AppTextStyles.body0.copyWith(color: AppColors.border),
        ),
      ],
    ),
    action: onOpen == null
        ? null
        : SnackBarAction(
            label: '보기',
            textColor: AppColors.brandConnection,
            onPressed: onOpen,
          ),
  );
}

/// 테스트가 이 막대를 찾는 자리.
const Key pushAlertBarKey = Key('push_alert_bar');
