import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/views/feed/feed.dart';
import 'package:political_think/views/messages/messages.dart';
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

  static const List<ZBottomBarNavigationItem> tabs = [
    ZBottomBarNavigationItem(
      icon: Icon(Icons.home),
      activeIcon: Icon(Icons.home),
      label: 'HOME',
      initialLocation: Feed.location,
    ),
    ZBottomBarNavigationItem(
      icon: Icon(Icons.storefront_outlined),
      activeIcon: Icon(Icons.storefront),
      label: 'SHOP',
      initialLocation: Search.location,
    ),
    ZBottomBarNavigationItem(
      icon: Icon(Icons.storefront_outlined),
      activeIcon: Icon(Icons.storefront),
      label: 'BUY',
      initialLocation: Messages.location,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: widget.child),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          _goOtherTab(context, index);
        },
        currentIndex: _getCurrentIndex(widget.location),
        items: tabs,
      ),
    );
  }

  void _goOtherTab(BuildContext context, int index) {
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
