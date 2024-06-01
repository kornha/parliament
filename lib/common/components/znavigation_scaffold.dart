import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/views/feed/feed.dart';
import 'package:political_think/views/games/games.dart';
import 'package:political_think/views/profile/profile.dart';
import 'package:political_think/views/maps/maps.dart';

class ZNavigationScaffold extends ConsumerStatefulWidget {
  const ZNavigationScaffold(
      {super.key, required this.child, required this.location});

  final String location;
  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ZNavigationScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: tabs should be abstracted from ZBottomBarNavigationItem and
    // NavigationRailDestination
    // TODO: move tabs to initstate
    var tabs = [
      ZBottomBarNavigationItem(
        icon: Icon(FontAwesomeIcons.rss, color: context.surfaceColor),
        activeIcon: Icon(FontAwesomeIcons.rss, color: context.secondaryColor),
        label: 'HOME',
        initialLocation: Feed.location,
      ),
      ZBottomBarNavigationItem(
        icon: Icon(FontAwesomeIcons.earthEurope, color: context.surfaceColor),
        activeIcon:
            Icon(FontAwesomeIcons.earthAmericas, color: context.secondaryColor),
        label: 'MAPS',
        initialLocation: Maps.location,
      ),
      ZBottomBarNavigationItem(
        icon:
            Icon(FontAwesomeIcons.solidChessRook, color: context.surfaceColor),
        activeIcon: Icon(FontAwesomeIcons.chess, color: context.secondaryColor),
        label: 'GAMES',
        initialLocation: Games.location,
      ),
      const ZBottomBarNavigationItem(
        icon: ProfileIcon(
          radius: IconSize.large / 2,
        ),
        activeIcon: ProfileIcon(
          radius: IconSize.large / 2,
        ),
        label: 'Profile',
        initialLocation: Profile.location,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Row(children: [
          context.isDesktop
              ? NavigationRail(
                  indicatorColor: Colors.transparent,
                  indicatorShape: const CircleBorder(),
                  backgroundColor: context.backgroundColor,
                  selectedIndex: _getCurrentIndex(widget.location),
                  onDestinationSelected: (int index) {
                    _goOtherTab(context, index, tabs);
                  },
                  destinations: tabs
                      .map((e) => NavigationRailDestination(
                            icon: e.icon,
                            selectedIcon: e.activeIcon,
                            label: Text(e.label!),
                          ))
                      .toList(),
                )
              : const SizedBox.shrink(),
          Expanded(child: widget.child),
        ]),
      ),
      bottomNavigationBar: context.isDesktop
          ? const SizedBox.shrink()
          : BottomNavigationBar(
              selectedFontSize: 0, // removes padding
              backgroundColor: context.backgroundColor,
              showUnselectedLabels: false,
              elevation: 0,
              showSelectedLabels: false,
              type: BottomNavigationBarType.fixed,
              onTap: (int index) {
                _goOtherTab(context, index, tabs);
              },
              currentIndex: _getCurrentIndex(widget.location),
              items: tabs,
            ),
    );
  }

  void _goOtherTab(
      BuildContext context, int index, List<ZBottomBarNavigationItem> tabs) {
    // if (index == _currentIndex) return;
    if (index > tabs.length - 1) return;
    GoRouter router = GoRouter.of(context);
    String location = tabs[index].initialLocation;
    if (index == _currentIndex && location == Feed.location) {
      ref.read(pagingControllerProvider.notifier).state?.refresh();
    }
    setState(() {
      _currentIndex = index;
    });
    router.go(location);
  }

  int _getCurrentIndex(String path) {
    switch (path) {
      case Profile.location:
        return 3;
      case Games.location:
        return 2;
      case Maps.location:
        return 1;
      default:
        return 0;
    }
  }
}

class ZBottomBarNavigationItem extends BottomNavigationBarItem {
  final String initialLocation;

  const ZBottomBarNavigationItem({
    required this.initialLocation,
    required Widget icon,
    String? label,
    Widget? activeIcon,
  }) : super(icon: icon, label: label, activeIcon: activeIcon ?? icon);
}
