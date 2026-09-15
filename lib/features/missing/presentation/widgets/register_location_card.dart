import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../register_draft_providers.dart';
import 'register_error_text.dart';
import 'register_text_field.dart';

/// 마지막 목격 위치(F-7.7). 주소 한 줄과 "지도에서 조정".
///
/// **폼 안에 움직이는 지도를 넣지 않는다.** 스크롤하는 폼 속 지도는 손가락이
/// 폼을 밀려는 건지 지도를 밀려는 건지 가르지 못한다. 핀은 전체 화면 지도에서
/// 옮기고, 여기서는 결과만 읽는다.
class RegisterLocationCard extends StatelessWidget {
  const RegisterLocationCard({
    required this.hasLocation,
    required this.address,
    required this.addressStatus,
    required this.onAdjust,
    required this.onAddressChanged,
    required this.addressFieldKey,
    this.errorText,
    super.key,
  });

  final bool hasLocation;
  final String address;
  final AddressStatus addressStatus;
  final VoidCallback onAdjust;
  final ValueChanged<String> onAddressChanged;
  final Key addressFieldKey;
  final String? errorText;

  static const Key adjustKey = Key('register_location_adjust');

  /// 카드에 적는 한 줄.
  String get _headline {
    if (!hasLocation) return '위치를 골라 주세요';

    return switch (addressStatus) {
      AddressStatus.looking => '주소를 찾는 중',
      AddressStatus.found when address.trim().isNotEmpty => address,
      _ => '고른 위치',
    };
  }

  @override
  Widget build(BuildContext context) {
    // 주소를 못 찾았으면 보호자가 적는다. 비워도 등록은 된다.
    final manual = hasLocation && addressStatus == AddressStatus.notFound;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormFieldLabel('마지막 목격 위치', required: true),
        const SizedBox(height: 8),
        Material(
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: errorText == null ? AppColors.border : AppColors.error,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: adjustKey,
            onTap: onAdjust,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
              child: Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 20,
                    color: hasLocation
                        ? AppColors.accent
                        : AppColors.textDisabled,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle0.copyWith(
                        color: hasLocation
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasLocation ? '지도에서 조정' : '지도에서 고르기',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        RegisterErrorText(errorText),
        if (manual) ...[
          const SizedBox(height: 10),
          RegisterTextField(
            fieldKey: addressFieldKey,
            value: address,
            onChanged: onAddressChanged,
            hint: '주소나 장소를 적어 주세요 (선택)',
            help: '주소를 자동으로 찾지 못했어요. 비워도 등록할 수 있습니다.',
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }
}
