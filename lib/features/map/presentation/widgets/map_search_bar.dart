import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';
import '../map_providers.dart';

/// 지도 위에 떠 있는 검색창과 필터 칩(F-5.1.1 · F-5.1.2).
///
/// 지도를 가리지 않도록 반투명 흰 카드로 얹는다. 목록(S2)의 검색창과 모양이
/// 다른 것은 배경이 지도이기 때문이다.
class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    required this.filter,
    required this.totalCount,
    required this.onKeywordChanged,
    required this.onFilterChanged,
    super.key,
  });

  final MapCaseFilter filter;

  /// '전체' 칩 옆에 붙는 건수.
  final int totalCount;

  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<MapCaseFilter> onFilterChanged;

  static const Key fieldKey = Key('map_search_field');

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => widget.onKeywordChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FloatingCard(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const AppIcon(
                AppIcons.glass,
                size: 16,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  key: MapSearchBar.fieldKey,
                  controller: _controller,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onKeywordChanged,
                  style: AppTextStyles.subtitle1,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: '지역 · 이름으로 찾기',
                    hintStyle: AppTextStyles.subtitle1.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final filter in MapCaseFilter.values) ...[
              if (filter != MapCaseFilter.values.first) const SizedBox(width: 7),
              _Pill(
                label: filter == MapCaseFilter.all
                    ? '${filter.label} ${widget.totalCount}'
                    : filter.label,
                selected: filter == widget.filter,
                onTap: () => widget.onFilterChanged(filter),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      color: selected ? AppColors.primary : null,
      radius: 22,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
      child: Text(
        label,
        style: AppTextStyles.subtitle0.copyWith(
          color: selected ? AppColors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 지도 위에 얹는 카드. 그림자로 지도와 층을 가른다.
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
    this.radius = 14,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: color ?? AppColors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
