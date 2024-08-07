import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ZTabBar extends StatelessWidget {
  const ZTabBar({
    super.key,
    required TabController tabController,
    required this.tabs,
  }) : _tabController = tabController;

  final TabController _tabController;
  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: tabs,
      indicatorColor: context.secondaryColor,
      // reduce width of indicator
      indicator: UnderlineTabIndicator(
        borderSide:
            BorderSide(width: context.sq.width!, color: context.secondaryColor),
        insets: EdgeInsets.symmetric(
          horizontal: context.sq.width!,
        ),
        borderRadius: BorderRadius.circular(context.sd.width!),
      ),
      dividerColor: Colors.transparent,
    );
  }
}
