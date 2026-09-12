import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/missing_case.dart';

/// 기본 정보(F-3.3). 실종 일시 · 장소 · 신체 · 인상착의.
///
/// 인상착의에 습관까지 적는 이유는, 옷은 갈아입어도 습관은 남기 때문이다.
class DetailFactList extends StatelessWidget {
  const DetailFactList({required this.detail, super.key});

  final MissingCaseDetail detail;

  @override
  Widget build(BuildContext context) {
    final body = _bodyLabel(detail);
    final place = _placeLabel(detail);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Fact(
          label: '실종 일시',
          // 오늘·어제로 줄이지 않는다. 사건의 기록으로 읽는 값이다.
          value: koreanDateTimeLabel(detail.missingAt, relative: false),
        ),
        if (place != null) _Fact(label: '실종 장소', value: place),
        if (body != null) _Fact(label: '신체', value: body),
        _Fact(label: '인상착의', value: detail.description),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textDisabled,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.subtitle1.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// `인천 남동구 구월동 로데오거리` + 주소로는 안 잡히는 위치 설명.
String? _placeLabel(MissingCaseDetail detail) {
  final address = detail.lastAddress;
  final place = detail.lastPlaceDetail;

  if (address == null || address.isEmpty) return place;
  if (place == null || place.isEmpty) return address;

  return '$address\n$place';
}

/// `키 122cm · 몸무게 24kg`. 둘 다 없으면 줄 자체를 빼서 빈 칸을 남기지 않는다.
String? _bodyLabel(MissingCaseDetail detail) {
  final parts = [
    if (detail.heightCm != null) '키 ${detail.heightCm}cm',
    if (detail.weightKg != null) '몸무게 ${detail.weightKg}kg',
  ];

  return parts.isEmpty ? null : parts.join(' · ');
}
