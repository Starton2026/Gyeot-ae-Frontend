import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVG 아이콘 하나를 그린다. `SvgPicture`를 직접 부르지 말고 이것을 쓴다.
///
/// 경로는 [AppIcons]의 상수로 넘긴다.
///
/// ```dart
/// AppIcon(AppIcons.bell, size: 24, semanticsLabel: '알림')
/// ```
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    this.size = 24,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  /// 아이콘 경로. [AppIcons]의 상수를 넘긴다.
  final String asset;

  /// 정사각 박스 한 변의 길이. 아이콘은 비율을 지킨 채 이 안에 들어간다.
  ///
  /// 원본 크기가 6~22px로 제각각이고 정사각형도 아니라서, 박스를 고정하고
  /// 안에서 맞춘다. 그래야 아이콘을 나란히 놓았을 때 정렬이 맞는다.
  final double size;

  /// 아이콘 색. 생략하면 주변 `IconTheme`의 색을 따른다.
  ///
  /// 원본 SVG가 전부 검정이라 여기서 칠해야 한다. 버튼이나 앱바 안에 넣으면
  /// 생략하는 쪽이 낫다. 비활성 상태 색까지 알아서 따라간다.
  final Color? color;

  /// 화면 낭독기가 읽을 이름.
  ///
  /// 뜻이 있는 아이콘에는 넣는다. 장식이면 생략한다. 생략하면 낭독기가 건너뛴다.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color;

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        asset,
        fit: BoxFit.contain,
        colorFilter: resolved == null
            ? null
            : ColorFilter.mode(resolved, BlendMode.srcIn),
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}

/// `assets/icons/`에 있는 아이콘 경로.
///
/// 상수 이름은 파일 이름을 그대로 따른다. 새 아이콘을 넣으면 여기에 상수 한 줄과
/// [all]에 한 줄을 추가한다. [all]에 빠지면 경로가 살아 있는지 검사하는 테스트가
/// 그 아이콘을 건너뛴다.
class AppIcons {
  const AppIcons._();

  static const String _dir = 'assets/icons';

  /// 알림 종.
  static const String bell = '$_dir/ic_bell.svg';

  /// 돋보기. 검색.
  static const String glass = '$_dir/ic_glass.svg';

  /// 카카오 말풍선. 로그인 버튼에만 쓴다.
  static const String kakao = '$_dir/ic_kakao.svg';

  /// 왼쪽 화살표. 뒤로 가기.
  static const String leftArrow = '$_dir/ic_left_arrow.svg';

  /// 위치 핀.
  static const String locationMarker = '$_dir/ic_location_marker.svg';

  /// 오른쪽 꺾쇠. 목록 항목의 더 보기.
  static const String rightAngleBracket = '$_dir/ic_right_angle_bracket.svg';

  /// 공유.
  static const String share = '$_dir/ic_share.svg';

  /// 등록된 아이콘 전부. 경로가 살아 있는지 검사하는 테스트가 이 목록을 돈다.
  static const List<String> all = [
    bell,
    glass,
    kakao,
    leftArrow,
    locationMarker,
    rightAngleBracket,
    share,
  ];
}
