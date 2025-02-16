import 'package:flutter/material.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/extensions.dart';

class ZScaffold extends StatelessWidget {
  final Color? backgroundColor;
  final Widget? appBar;
  final Widget body;
  final FloatingActionButton? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final Widget? bottomNavigationBar;
  final bool defaultPadding;
  final bool defaultMargin;
  final bool defaultSafeArea;
  final bool ignoreConstraints;
  final ScrollPhysics scrollPhysics;
  final bool? ignoreScrollView;
  final bool pinAppBar;

  const ZScaffold({
    super.key,
    this.backgroundColor,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.bottomNavigationBar,
    this.scrollPhysics = const BouncingScrollPhysics(),
    this.defaultPadding = true,
    this.defaultMargin = true,
    this.defaultSafeArea = true,
    this.ignoreConstraints = false,
    this.pinAppBar = false,
    this.ignoreScrollView, // whether or not include in scroll controller, defaults to scrollPhysics.allowUserScrolling
  });

  @override
  Widget build(BuildContext context) {
    // whether or not to include scrollView wrapper
    bool scrollView = ignoreScrollView != null
        ? !ignoreScrollView!
        : scrollPhysics.allowUserScrolling;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      bottomNavigationBar: bottomNavigationBar,
      appBar: null,
      body: SafeArea(
        left: defaultSafeArea,
        right: defaultSafeArea,
        top: defaultSafeArea,
        bottom: defaultSafeArea,
        child: NestedScrollView(
          //controller: scrollController,
          physics: scrollPhysics,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                surfaceTintColor: context.backgroundColor,
                backgroundColor: context.backgroundColorWithOpacity,
                // pinned: true,
                title: appBar ?? ZAppBar(),
                titleSpacing: context.sh.width,
                centerTitle: true,
                floating: true,
                snap: true,
                pinned: pinAppBar ||
                    context.isDesktop, //limits buggyness on desktop browser
                automaticallyImplyLeading: false,
                forceElevated: innerBoxIsScrolled,
                elevation: 0,
              ),
            ];
          },
          body: scrollView
              ? SingleChildScrollView(
                  child: ignoreConstraints
                      ? body
                      : ZscaffoldConstraints(
                          defaultPadding: defaultPadding,
                          defaultMargin: defaultMargin,
                          child: body,
                        ),
                )
              : ignoreConstraints
                  ? body
                  : ZscaffoldConstraints(
                      defaultPadding: defaultPadding,
                      defaultMargin: defaultMargin,
                      child: body,
                    ),
        ),
      ),
    );
  }
}

class ZscaffoldConstraints extends StatelessWidget {
  final Widget child;
  final bool defaultPadding;
  final bool defaultMargin;
  const ZscaffoldConstraints({
    super.key,
    required this.child,
    this.defaultPadding = true,
    this.defaultMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: defaultMargin
            ? context.blockMarginSmall.copyWith(top: 0, bottom: 0)
            : EdgeInsets.zero,
        padding: defaultPadding
            ? context.blockPaddingSmall.copyWith(top: 0, bottom: 0)
            : EdgeInsets.zero,
        width: context.blockSizeLarge.width, // large or medium?
        // height: context.blockSize.height,
        child: child,
      ),
    );
  }
}
