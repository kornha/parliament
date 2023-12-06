import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ZScaffold extends StatelessWidget {
  final Color? backgroundColor;
  final Widget? appBar;
  final Widget body;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;

  const ZScaffold({
    super.key,
    this.backgroundColor,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: NestedScrollView(
        controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: context.backgroundColor,
              pinned: true,
              title: appBar,
              centerTitle: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              forceElevated: innerBoxIsScrolled,
              elevation: 0,
            ),
          ];
        },
        body: body,
      ), //body,
      backgroundColor: context.backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
