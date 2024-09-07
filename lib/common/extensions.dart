import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;

extension ProviderExt on WidgetRef {
  get authWatch => watch(authProvider);
  get authRead => read(authProvider);
  AsyncValue<ZUser?> userWatch(uid) => watch(zuserProvider(uid));
  AsyncValue<ZUser?> userRead(uid) => read(zuserProvider(uid));
  AsyncValue<ZUser?> selfUserWatch() =>
      watch(zuserProvider(authRead.authUser!.uid));
  AsyncValue<ZUser?> selfUserRead() =>
      read(zuserProvider(authRead.authUser!.uid));
  // gets the user assuming logged in
  ZUser user() => read(zuserProvider(authRead.authUser!.uid)).value!;
  AsyncValue<List<ZUser>?> usersWatch(uids) => watch(zusersProvider(uids));
  AsyncValue<List<ZUser>?> usersRead(uids) => read(zusersProvider(uids));

  AsyncValue<Vote?> voteWatch(String pid, String uid, VoteType type) =>
      watch(voteProvider((pid, uid, type)));
  AsyncValue<Vote?> voteRead(String pid, String uid, VoteType type) =>
      read(voteProvider((pid, uid, type)));

  AsyncValue<Story?> storyWatch(String sid) => watch(storyProvider(sid));
  AsyncValue<Story?> storyRead(String sid) => read(storyProvider(sid));

  AsyncValue<Post?> postWatch(String pid) => watch(postProvider(pid));
  AsyncValue<Post?> postRead(String pid) => read(postProvider(pid));
  AsyncValue<List<Post>?> primaryPostsFromStoriesWatch(String sid) =>
      watch(primaryPostsFromStoryProvider(sid));
  AsyncValue<List<Post>?> primaryPostsFromStoriesRead(String sid) =>
      read(primaryPostsFromStoryProvider(sid));
  AsyncValue<List<Post>?> postsFromStoryWatch(String sid) =>
      watch(postsFromStoryProvider(sid));
  AsyncValue<List<Post>?> postsFromStoryRead(String sid) =>
      read(postsFromStoryProvider(sid));
  AsyncValue<List<Post>?> postsFromEntityWatch(String eid) =>
      watch(postsFromEntityProvider(eid));
  AsyncValue<List<Post>?> postsFromEntityRead(String eid) =>
      read(postsFromEntityProvider(eid));

  AsyncValue<List<Statement>?> statementsFromStoriesWatch(String sid) =>
      watch(statementsFromStoryProvider(sid));
  AsyncValue<List<Statement>?> statementsFromStoriesRead(String sid) =>
      read(statementsFromStoryProvider(sid));

  AsyncValue<Entity?> entityWatch(String eid) => watch(entityProvider(eid));
  AsyncValue<Entity?> entityRead(String eid) => read(entityProvider(eid));
  AsyncValue<List<Entity>?> entitiesFromPostsWatch(List<String> pids) =>
      watch(entitiesFromPostsProvider(pids));
  AsyncValue<List<Entity>?> entitiesFromPostsRead(List<String> pids) =>
      read(entitiesFromPostsProvider(pids));

  AsyncValue<Room?> activeRoomWatch(String parentId) =>
      watch(latestRoomProvider((parentId)));
  AsyncValue<Room?> activeRoomRead(String parentId) =>
      read(latestRoomProvider((parentId)));

  AsyncValue<List<ct.Message>?> messagesWatch(String rid, int limit) =>
      watch(messagesProvider((rid, limit)));
  refreshMessages(String rid, int limit) =>
      refresh(messagesProvider((rid, limit)));
}

extension ThemeExt on BuildContext {
  // need to change this to use the theme
  // backgroundColor was deprecated
  Color get backgroundColor => Theme.of(this).colorScheme.surface;
  Color get onBackgroundColor => Theme.of(this).colorScheme.onSurface;
  Color get surfaceColor => Theme.of(this).colorScheme.surfaceDim;
  Color get surfaceColorBright => Theme.of(this).colorScheme.surfaceBright;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurfaceVariant;
  Color get backgroundColorWithOpacity => backgroundColor.withOpacity(0.55);

  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get primaryColorWithOpacity => primaryColor.withOpacity(0.2);
  Color get onPrimaryColor => Theme.of(this).colorScheme.onPrimary;
  Color get errorColor => Theme.of(this).colorScheme.error;
  Color get onErrorColor => Theme.of(this).colorScheme.onError;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  Color get onSecondaryColor => Theme.of(this).colorScheme.onSecondary;
  TargetPlatform get platform => Theme.of(this).platform;

  bool get isAndroid => platform == TargetPlatform.android;
  bool get isIOS => platform == TargetPlatform.iOS;
  bool get isMacOS => platform == TargetPlatform.macOS;
  bool get isWindows => platform == TargetPlatform.windows;
  bool get isFuchsia => platform == TargetPlatform.fuchsia;
  bool get isLinux => platform == TargetPlatform.linux;
}

extension MediaQueryExt on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  MediaQueryData get mediaQueryData => MediaQuery.of(this);
  EdgeInsets get mediaQueryPadding => MediaQuery.of(this).padding;
  EdgeInsets get mediaQueryViewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get mediaQueryViewInsets => MediaQuery.of(this).viewInsets;
  Orientation get orientation => MediaQuery.of(this).orientation;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get alwaysUse24HourFormat => MediaQuery.of(this).alwaysUse24HourFormat;
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;
  Brightness get platformBrightness => MediaQuery.of(this).platformBrightness;
  double get textScaleFactor => MediaQuery.of(this).textScaleFactor;
  double get mediaQueryShortestSide => screenSize.shortestSide;

  // note we use top and left instead of horizontal/vertical because this small
  Size get blockSize => Size(
        min(screenSize.width - blockMargin.horizontal - blockPadding.horizontal,
            800),
        min(screenSize.width - blockMargin.horizontal - blockPadding.horizontal,
                800) *
            9 /
            16,
      );

  // TODO: Should this be static?
  Size get blockSizeSmall => Size(
        min(blockSize.width / 2.5, 160),
        min(blockSize.width / 2.5, 160) * 9 / 16,
      );

  Size get blockSizeLarge => Size(
      min(screenSize.width - blockMargin.horizontal, 1000),
      min(screenSize.width - blockMargin.horizontal, 1000) * 9 / 16);

  Size get imageSize => blockSize;
  Size get imageSizeSmall => blockSizeSmall;

  // TODO: Hack, we need to fix all this sizing
  Size get screenBlock {
    // adjust for safe area mobile
    var bottom = isWeb ? 0 : kToolbarHeight * 2;
    return Size(
        screenSize.width - blockMargin.horizontal - blockPadding.horizontal,
        screenSize.height -
            blockMargin.vertical * 2 -
            blockPadding.vertical * 2 -
            bottom);
  }

  // size
  bool get isMobile => screenSize.width < 600;
  bool get isTablet => !isMobile && screenSize.width < 1000;
  bool get isDesktop => screenSize.width > 1000;

  // platform
  bool get isWeb => kIsWeb;
  bool get isTrueMobile => isMobile && !kIsWeb;
  bool get isTrueTablet => isTablet && !kIsWeb;

  /// True if the current device is Phone or Tablet
  bool get isMobileOrTablet => isMobile || isTablet;
  Brightness get brightness => MediaQuery.of(this).platformBrightness;
  bool get isDarkMode => brightness == Brightness.dark;
  GoRouterState get router => GoRouterState.of(this);
}

extension Spacing on BuildContext {
  EdgeInsets get pf => const EdgeInsets.symmetric(
      horizontal: Margins.full, vertical: Margins.full);

  EdgeInsets get pf3 => EdgeInsets.symmetric(
      horizontal: screenSize.width * 0.33, vertical: Margins.half);
  EdgeInsets get pfh => const EdgeInsets.symmetric(
      vertical: Margins.half, horizontal: Margins.full);
  EdgeInsets get ph => const EdgeInsets.symmetric(
      horizontal: Margins.half, vertical: Margins.half);
  EdgeInsets get pq => const EdgeInsets.symmetric(
      horizontal: Margins.quarter, vertical: Margins.quarter);
  EdgeInsets get pz => const EdgeInsets.all(0);
  EdgeInsets get mf => const EdgeInsets.symmetric(
      horizontal: Margins.full, vertical: Margins.full);
  EdgeInsets get mh => const EdgeInsets.symmetric(
      horizontal: Margins.half, vertical: Margins.half);
  EdgeInsets get mz => const EdgeInsets.all(0);

  EdgeInsets get blockMargin => const EdgeInsets.symmetric(
      horizontal: Margins.half, vertical: Margins.half);
  EdgeInsets get blockPaddingSmall => const EdgeInsets.symmetric(
      horizontal: Margins.quarter, vertical: Margins.quarter);
  EdgeInsets get blockPadding => const EdgeInsets.symmetric(
      horizontal: Margins.half, vertical: Margins.half);
  EdgeInsets get blockPaddingExtra => const EdgeInsets.symmetric(
      horizontal: Margins.full, vertical: Margins.full);

  // double get blockWidth =>
  //     isMobileOrTablet ? Block.blockWidthSmall : Block.blockWidthLarge;
  SizedBox get soc =>
      const SizedBox(height: Margins.octuple, width: Margins.octuple);
  SizedBox get ssp =>
      const SizedBox(height: Margins.septuple, width: Margins.septuple);
  SizedBox get ssx =>
      const SizedBox(height: Margins.sextuple, width: Margins.sextuple);
  SizedBox get sqt =>
      const SizedBox(height: Margins.quintuple, width: Margins.quintuple);
  SizedBox get sqd =>
      const SizedBox(height: Margins.quadruple, width: Margins.quadruple);
  SizedBox get st =>
      const SizedBox(height: Margins.triple, width: Margins.triple);
  SizedBox get sd =>
      const SizedBox(height: Margins.twice, width: Margins.twice);
  SizedBox get sf => const SizedBox(height: Margins.full, width: Margins.full);
  SizedBox get sth =>
      const SizedBox(height: Margins.threeHalf, width: Margins.threeHalf);
  SizedBox get stq =>
      const SizedBox(height: Margins.threeQuarter, width: Margins.threeQuarter);
  SizedBox get sh => const SizedBox(height: Margins.half, width: Margins.half);
  SizedBox get sq =>
      const SizedBox(height: Margins.quarter, width: Margins.quarter);
  SizedBox get sl =>
      const SizedBox(height: Margins.least, width: Margins.least);
}

extension ModalExt on BuildContext {
  // HACK scrollview needed for long posts but messes with the photo_view
  // consider other approach
  void showFullScreenModal(Widget child, {bool useScrollView = true}) {
    showCupertinoDialog(
      context: this,
      useRootNavigator: true,
      builder: (BuildContext context) {
        // Note: we make this a scaffold so we can easily pop for any child
        // TODO: Any child needs to be a DialogContainer (see in that class why)
        // should perhaps refactor for better abstraction
        return ZScaffold(
          defaultSafeArea: false,
          appBar: ZAppBar(
            leading: IconButton(
              icon: Icon(FontAwesomeIcons.xmark, color: context.primaryColor),
              onPressed: () {
                context.pop();
              },
            ),
          ),
          body: useScrollView ? SingleChildScrollView(child: child) : child,
        );
      },
    );
  }

  void showModal(Widget child) {
    if (isDesktop) {
      showCupertinoModalPopup(
        context: this,
        builder: (BuildContext context) {
          return Center(
            child: Material(
              color: context.backgroundColor,
              child: SizedBox(
                width: context.blockSize.width,
                // TODO: NEED TO FIX SIZING
                height: context.blockSize.height / 2,
                child: child,
              ),
            ),
          );
        },
      );
      return;
    }
    showCupertinoModalBottomSheet(
      barrierColor: surfaceColor.withOpacity(0.9),
      context: this,
      expand: false,
      useRootNavigator: true,
      builder: (context) => Material(
        color: context.backgroundColor,
        // Note: we use this to show above keyboard
        child: SingleChildScrollView(
          //always bounce
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: child,
        ),
      ),
    );
  }

  // TODO: We use this custom library since Material snackbar shows behind modals
  void showToast(String message, {bool isError = false}) {
    FToast().init(this).showToast(
          positionedToastBuilder: (context, child) {
            return Positioned(
              bottom: Margins.full,
              left: Margins.full,
              child: child,
            );
          },
          child: Container(
            padding: blockPadding,
            width: blockSize.width,
            height: st.height,
            decoration: BoxDecoration(
              borderRadius: BRadius.least,
              color: isError ? errorColor : secondaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  isError ? ZIcons.error : ZIcons.check,
                  color: isError ? onErrorColor : onSecondaryColor,
                  size: iconSizeStandard,
                ),
                sh,
                Text(
                  message,
                  style: TextStyle(
                    color: isError ? onErrorColor : onSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
  }

  // void showSnackbar(String message) {
  //   // cupertino has no snackbar
  //   ScaffoldMessenger.of(this).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //     ),
  //   );
  // }

  // void showDialog(
  //   String title,
  //   String message,
  // ) {
  //   showCupertinoDialog(
  //     context: this,
  //     builder: (BuildContext context) {
  //       return CupertinoAlertDialog(
  //         title: Text(title),
  //         content: Text(message),
  //         actions: <Widget>[
  //           CupertinoDialogAction(
  //             isDefaultAction: true,
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text("OK"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
}

extension ConstantsExt on BuildContext {
  //Widget get sendIcon => Icon(Icons.send, color: onSurfaceColor);
  //Widget get deliveredIcon => Icon(Icons.receipt, color: primaryColor);

  double get iconSizeTiny => IconSize.tiny;
  double get iconSizeSmall => IconSize.small;
  double get iconSizeStandard => IconSize.standard;
  double get iconSizeLarge => IconSize.large;
  double get iconSizeXL => IconSize.xl;
  double get iconSizeXXL => IconSize.xxl;
  double get iconSizeXXXL => IconSize.xxxl;
}

extension TextExt on BuildContext {
  // TODO: overriding this here and not using from theme
  TextStyle get ah2 => TextStyle(
      fontSize: Theme.of(this).textTheme.headlineMedium!.fontSize,
      color: primaryColor,
      fontFamily: "Minecart");
  TextStyle get ah3 => TextStyle(
      fontSize: Theme.of(this).textTheme.headlineSmall!.fontSize,
      color: primaryColor,
      fontFamily: "Minecart");
  TextStyle get al => TextStyle(
      fontSize: Theme.of(this).textTheme.bodyLarge!.fontSize,
      color: primaryColor,
      fontFamily: "Minecart");
  TextStyle get am => TextStyle(
      fontSize: Theme.of(this).textTheme.bodyMedium!.fontSize,
      color: primaryColor,
      fontFamily: "Minecart");
  TextStyle get as => TextStyle(
      fontSize: Theme.of(this).textTheme.bodySmall!.fontSize,
      color: primaryColor,
      fontFamily: "Minecart");

  TextStyle get d1 => Theme.of(this).textTheme.displayLarge!;
  TextStyle get d2 => Theme.of(this).textTheme.displayMedium!;
  TextStyle get d3 => Theme.of(this).textTheme.displaySmall!;
  TextStyle get h1 => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get h2 => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get h3 => Theme.of(this).textTheme.headlineSmall!;
  TextStyle get h4 => Theme.of(this).textTheme.titleLarge!;
  TextStyle get h5 => Theme.of(this).textTheme.titleMedium!;
  TextStyle get h6 => Theme.of(this).textTheme.titleSmall!;
  TextStyle get l => Theme.of(this).textTheme.bodyLarge!;
  TextStyle get m => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get s => Theme.of(this).textTheme.bodySmall!;

  TextStyle get d1b => d1.copyWith(fontWeight: FontWeight.bold);
  TextStyle get d2b => d2.copyWith(fontWeight: FontWeight.bold);
  TextStyle get d3b => d3.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h1b => h1.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h2b => h2.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h3b => h3.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h4b => h4.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h5b => h5.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h6b => h6.copyWith(fontWeight: FontWeight.bold);
  TextStyle get lb => l.copyWith(fontWeight: FontWeight.bold);
  TextStyle get mb => m.copyWith(fontWeight: FontWeight.bold);
  TextStyle get sb => s.copyWith(fontWeight: FontWeight.bold);
}
