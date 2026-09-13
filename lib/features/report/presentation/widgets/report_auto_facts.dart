import 'package:flutter/material.dart';

import '../../../../core/format/time_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../report_draft_providers.dart';
import 'report_field_label.dart';

/// 자동으로 담긴 위치(F-4.3)와 시간(F-4.4).
///
/// **묻지 않고 채워 넣는다.** 입력란을 하나 늘릴 때마다 제보 하나가 사라진다고
/// 본다. 대신 둘 다 눈에 보이게 적어두고, 틀렸을 때만 고치게 한다.
///
/// 다만 **어디서 온 값인지는 적는다.** 사진에 박힌 좌표와 지금 내가 선 자리는
/// 다른 값이고, 앨범에서 고른 사진이면 뒤쪽이 틀릴 수 있다.
class ReportAutoFacts extends StatelessWidget {
  const ReportAutoFacts({
    required this.draft,
    required this.deviceLabel,
    required this.onEditPlace,
    required this.onRetryLocation,
    required this.onEditTime,
    super.key,
  });

  final ReportDraft draft;

  /// 기기 위치에 붙일 이름. "현재 위치".
  final String deviceLabel;

  final VoidCallback onEditPlace;
  final VoidCallback onRetryLocation;
  final VoidCallback onEditTime;

  static const Key editPlaceKey = Key('report_edit_place');
  static const Key editTimeKey = Key('report_edit_time');

  bool get _hasLocation => draft.fixSource != ReportLocationSource.none;

  String get _locationTitle => switch (draft.fixSource) {
    ReportLocationSource.photo => '사진에 찍힌 위치',
    ReportLocationSource.device => deviceLabel,
    ReportLocationSource.none => '위치를 못 받았어요',
  };

  String get _locationNote {
    if (!_hasLocation) return '위치 없이도 제보할 수 있어요';
    if (draft.placeName.isNotEmpty) return draft.placeName;

    return draft.fixSource == ReportLocationSource.photo
        ? '사진에 저장된 촬영 위치입니다'
        : '장소 이름을 더하면 찾기 쉬워요';
  }

  String get _locationAction {
    if (!_hasLocation) return '다시 시도';

    // 좌표를 바꾸는 것이 아니라 그 위에 이름을 덧붙이는 것이다.
    // "수정"이라고 적으면 위치를 옮기는 줄 안다.
    return draft.placeName.isEmpty ? '장소 추가' : '장소 수정';
  }

  String get _timeNote => switch (draft.timeSource) {
    ReportTimeSource.photo => '사진에 찍힌 촬영 시각',
    ReportTimeSource.manual => '직접 고친 시각',
    ReportTimeSource.now => '사진을 올린 시각',
  };

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
                icon: _hasLocation
                    ? Icons.place_outlined
                    : Icons.location_disabled_outlined,
                title: _locationTitle,
                subtitle: _locationNote,
                action: _locationAction,
                muted: !_hasLocation,
                editKey: editPlaceKey,
                onEdit: _hasLocation ? onEditPlace : onRetryLocation,
              ),
              const Divider(),
              _FactRow(
                icon: Icons.schedule_outlined,
                title: koreanDateTimeLabel(draft.observedAt),
                subtitle: _timeNote,
                // 이쪽은 값을 실제로 갈아치운다.
                action: '수정',
                editKey: editTimeKey,
                onEdit: onEditTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        if (draft.needsLocationCheck)
          Text(
            '앨범에서 고른 사진이에요. 목격한 곳이 지금 위치가 맞는지 확인해 주세요.',
            style: AppTextStyles.body0.copyWith(
              color: AppColors.textCareAccent,
            ),
          )
        else
          Text(
            '나중에 올리는 사진이라면 시간을 실제 목격 시각으로 바꿔주세요.',
            style: AppTextStyles.body0.copyWith(
              color: AppColors.textSecondary,
            ),
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
    required this.action,
    required this.editKey,
    required this.onEdit,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// 오른쪽 버튼에 적는 말. 줄마다 하는 일이 달라서 따로 받는다.
  final String action;

  /// 값이 비어 있는 줄. 담긴 정보처럼 진하게 적지 않는다.
  final bool muted;

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
              color: muted
                  ? AppColors.backgroundSubtle
                  : AppColors.brandConnectionSurface,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 17,
              color: muted ? AppColors.textDisabled : AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle0.copyWith(
                    color: muted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
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
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
