import 'package:flutter/material.dart';

import '../../../report/data/report.dart';
import '../../data/missing_case.dart';
import 'detail_fact_list.dart';
import 'detail_name_line.dart';
import 'detail_photo_carousel.dart';
import 'detail_reports_section.dart';
import 'detail_status_line.dart';

/// 실종자 상세(S3)의 본문.
///
/// 사진과 본문이 **한 스크롤 안에** 있어야 상단바가 사진을 덮으며 올라온다.
class DetailBody extends StatelessWidget {
  const DetailBody({
    required this.detail,
    required this.heroHeight,
    required this.scrollController,
    required this.nameKey,
    this.onToggleConfirmed,
    this.onToggleHidden,
    super.key,
  });

  final MissingCaseDetail detail;
  final double heroHeight;
  final ScrollController scrollController;

  /// 상단바가 제목을 이어받는 지점을 재려고 화면이 넘겨주는 키.
  final GlobalKey nameKey;

  /// 보호자만 준다. 제보 카드마다 확인함·숨기기가 붙는다.
  final ValueChanged<Report>? onToggleConfirmed;
  final ValueChanged<Report>? onToggleHidden;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailPhotoCarousel(photos: detail.photos, height: heroHeight),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailStatusLine(
                  status: detail.status,
                  elapsedMinutes: detail.elapsedMinutes,
                ),
                const SizedBox(height: 11),
                DetailNameLine(
                  key: nameKey,
                  name: detail.name,
                  ageGenderLabel: formatAgeGender(
                    detail.age,
                    detail.gender,
                    separator: ' · ',
                  ),
                ),
                const SizedBox(height: 16),
                DetailFactList(detail: detail),
                const SizedBox(height: 6),
                DetailReportsSection(
                  caseId: detail.id,
                  onToggleConfirmed: onToggleConfirmed,
                  onToggleHidden: onToggleHidden,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
