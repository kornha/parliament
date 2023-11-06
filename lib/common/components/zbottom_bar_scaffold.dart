import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/views/feed/feed.dart';
import 'package:political_think/views/messages/messages.dart';
import 'package:political_think/views/profile/profile.dart';
import 'package:political_think/views/search/search.dart';

class ZBottomBarScaffold extends ConsumerStatefulWidget {
  const ZBottomBarScaffold(
      {super.key, required this.child, required this.location});

  final String location;
  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ZBottomBarScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    var tabs = [
      const ZBottomBarNavigationItem(
        icon: Icon(Icons.home),
        activeIcon: Icon(Icons.home),
        label: 'HOME',
        initialLocation: Feed.location,
      ),
      const ZBottomBarNavigationItem(
        icon: Icon(Icons.storefront_outlined),
        activeIcon: Icon(Icons.storefront),
        label: 'SHOP',
        initialLocation: Search.location,
      ),
      const ZBottomBarNavigationItem(
        icon: Icon(Icons.storefront_outlined),
        activeIcon: Icon(Icons.storefront),
        label: 'BUY',
        initialLocation: Messages.location,
      ),
      const ZBottomBarNavigationItem(
        icon: ProfileIcon(),
        activeIcon: ProfileIcon(),
        label: 'Profile',
        initialLocation: Profile.location,
      ),
    ];
    return Scaffold(
      body: SafeArea(child: widget.child),
      backgroundColor: context.backgroundColor,
      bottomNavigationBar: BottomNavigationBar(
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
    if (index == _currentIndex) return;
    if (index > tabs.length - 1) return;
    GoRouter router = GoRouter.of(context);
    String location = tabs[index].initialLocation;
    setState(() {
      _currentIndex = index;
    });
    router.go(location);
  }

  int _getCurrentIndex(String path) {
    switch (path) {
      case Profile.location:
        return 3;
      case Messages.location:
        return 2;
      case Search.location:
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
