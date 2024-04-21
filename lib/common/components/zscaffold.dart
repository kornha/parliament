import 'package:flutter/material.dart';
import 'package:political_think/common/chat/flutter_chat_ui.dart';
import 'package:political_think/common/extensions.dart';

class ZScaffold extends StatelessWidget {
  final Color? backgroundColor;
  final Widget? appBar;
  final Widget body;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;
  final bool defaultPadding;
  final bool defaultMargin;
  final bool defaultSafeArea;

  const ZScaffold({
    super.key,
    this.backgroundColor,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.bottomNavigationBar,
    this.scrollController,
    this.defaultPadding = true,
    this.defaultMargin = true,
    this.defaultSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: NestedScrollView(
        //controller: scrollController,
        physics: const NeverScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              surfaceTintColor: context.backgroundColor,
              backgroundColor: context.backgroundColorWithOpacity,
              // pinned: true,
              title: appBar,
              titleSpacing: context.sh.width,
              centerTitle: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              forceElevated: innerBoxIsScrolled,
              elevation: 0,
            ),
          ];
        },
        body: SafeArea(
          left: defaultSafeArea,
          right: defaultSafeArea,
          top: defaultSafeArea,
          bottom: defaultSafeArea,
          child: Container(
            margin: defaultMargin
                ? context.blockMargin.copyWith(top: 0, bottom: 0)
                : EdgeInsets.zero,
            padding: defaultPadding
                ? context.blockPadding.copyWith(top: 0, bottom: 0)
                : EdgeInsets.zero,
            width: context.blockSize.width,
            // height: context.blockSize.height,
            child: body,
          ),
        ),
      ), //body,
      backgroundColor: context.backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
