import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'report_field_label.dart';

/// 자동으로 담긴 위치(F-4.3)와 시간(F-4.4).
///
/// **묻지 않고 채워 넣는다.** 입력란을 하나 늘릴 때마다 제보 하나가 사라진다고
/// 본다. 대신 둘 다 눈에 보이게 적어두고, 틀렸을 때만 고치게 한다.
class ReportAutoFacts extends StatelessWidget {
  const ReportAutoFacts({
    required this.address,
    required this.placeName,
    required this.observedAt,
    required this.observedAtEdited,
    required this.onEditPlace,
    required this.onEditTime,
    super.key,
  });

  /// 지금 위치. 역지오코딩한 주소가 있으면 그것을 적는다.
  final String address;

  /// 사용자가 적어둔 장소 이름. 비어 있으면 적어달라고 권한다.
  final String placeName;

  final DateTime observedAt;

  /// 자동으로 담긴 값을 사용자가 고쳤다.
  final bool observedAtEdited;

  final VoidCallback onEditPlace;
  final VoidCallback onEditTime;

  static const Key editPlaceKey = Key('report_edit_place');
  static const Key editTimeKey = Key('report_edit_time');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReportFieldLabel('자동으로 담긴 정보'),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _FactRow(
                icon: Icons.place_outlined,
                title: address,
                subtitle: placeName.isEmpty
                    ? '장소 이름을 더하면 찾기 쉬워요'
                    : placeName,
                editKey: editPlaceKey,
                onEdit: onEditPlace,
              ),
              const Divider(),
              _FactRow(
                icon: Icons.schedule_outlined,
                title: koreanDateTimeLabel(observedAt),
                subtitle: observedAtEdited ? '직접 고친 시각' : '사진을 올린 시각',
                editKey: editTimeKey,
                onEdit: onEditTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '나중에 올리는 사진이라면 시간을 실제 목격 시각으로 바꿔주세요.',
          style: AppTextStyles.body0.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.editKey,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Key editKey;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 오른쪽이 6인 것은 버튼이 제 여백을 8 갖고 있어서다. 합쳐서 14,
      // 왼쪽과 같아진다.
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.brandConnectionSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle0,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppTextStyles.body0.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            key: editKey,
            onPressed: onEdit,
            // 기본 버튼은 글자가 17인데도 터치 영역 48을 잡는다. 아이콘과
            // 두 줄 글자가 38이라, 그 차이만큼 줄이 혼자 부푼다.
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}
