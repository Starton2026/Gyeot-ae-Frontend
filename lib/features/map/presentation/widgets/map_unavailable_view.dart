import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 지도를 못 그리는 이유.
enum MapUnavailableReason {
  /// 빌드에 카카오맵 키가 들어오지 않았다.
  noKey(
    '지도 키가 설정되지 않았어요',
    'env/dev.json의 KAKAO_MAP_KEY를 채우고,\n--dart-define-from-file=env/dev.json 으로 실행해 주세요',
  ),

  /// 키는 있는데 카카오가 인증을 거절했다. 키 해시나 패키지명이 등록과 다르다.
  authFailed(
    '지도를 불러오지 못했어요',
    '카카오 개발자 콘솔에 이 기기의 키 해시와\n패키지명이 등록되어 있는지 확인해 주세요',
  );

  const MapUnavailableReason(this.title, this.guide);

  final String title;
  final String guide;
}

/// 지도가 안 뜰 때 그 자리에 이유를 적는다.
///
/// 흰 판만 남으면 화면이 고장 난 것인지, 키가 없는 것인지, 인증이 막힌 것인지
/// 알 수 없다. 지도를 못 그리는 것은 **개발 중에 흔한 상태**라서 화면이 직접
/// 말해야 한다.
class MapUnavailableView extends StatelessWidget {
  const MapUnavailableView({required this.reason, this.detail, super.key});

  final MapUnavailableReason reason;

  /// SDK가 준 오류 문구. 디버그 중에만 의미가 있다.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final message = detail;

    return ColoredBox(
      color: AppColors.backgroundSubtle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 44,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 14),
              Text(
                reason.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title0,
              ),
              const SizedBox(height: 8),
              Text(
                reason.guide,
                textAlign: TextAlign.center,
                style: AppTextStyles.body0.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
