import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:political_think/common/constants.dart';
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
  AsyncValue<Vote?> voteWatch(String pid, String uid, VoteType type) =>
      watch(voteProvider((pid, uid, type)));
  AsyncValue<Vote?> voteRead(String pid, String uid, VoteType type) =>
      read(voteProvider((pid, uid, type)));
  AsyncValue<ZUser?> selfUserWatch() =>
      watch(zuserProvider(authRead.authUser!.uid));
  AsyncValue<ZUser?> selfUserRead() =>
      read(zuserProvider(authRead.authUser!.uid));
  ZUser user() => read(zuserProvider(authRead.authUser!.uid)).value!;
  AsyncValue<Story?> storyWatch(String sid) => watch(storyProvider(sid));
  AsyncValue<Story?> storyRead(String sid) => read(storyProvider(sid));
  AsyncValue<Post?> postWatch(String pid) => watch(postProvider(pid));
  AsyncValue<Post?> postRead(String pid) => read(postProvider(pid));
  AsyncValue<List<Post>?> postsFromStoriesWatch(String sid) =>
      watch(postsFromStoryProvider(sid));
  AsyncValue<List<Post>?> postsFromStoriesRead(String sid) =>
      read(postsFromStoryProvider(sid));

  AsyncValue<Room?> activeRoomWatch(String parentId, RoomParentType type) =>
      watch(latestRoomProvider((parentId, type.collectionName)));
  AsyncValue<Room?> activeRoomRead(String parentId, RoomParentType type) =>
      read(latestRoomProvider((parentId, type.collectionName)));

  AsyncValue<List<ct.Message>?> messagesWatch(Room room, int limit) =>
      watch(messagesProvider((room, limit)));
  refreshMessages(Room room, int limit) =>
      refresh(messagesProvider((room, limit)));
}

extension ThemeExt on BuildContext {
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get backgroundColor => Theme.of(this).colorScheme.background;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get onPrimaryColor => Theme.of(this).colorScheme.onPrimary;
  Color get onBackgroundColor => Theme.of(this).colorScheme.onBackground;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
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
  bool get isWeb => kIsWeb;
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
  Size get imageSize => Size(
      screenSize.width - blockPadding.horizontal - blockMargin.horizontal,
      (screenSize.width - blockPadding.horizontal - blockMargin.horizontal) *
          9.0 /
          16.0);
  Size get imageSizeSmall => Size(
      screenSize.width / 2.5 - blockPadding.horizontal - blockMargin.horizontal,
      (screenSize.width / 2.5 -
              blockPadding.horizontal -
              blockMargin.horizontal) *
          9.0 /
          16.0);
  // note we use top and left instead of horizontal/vertical because this small
  Size get blockSizeSmall => Size(
      screenSize.width - blockMargin.horizontal - blockPadding.horizontal,
      imageSizeSmall.height + blockMargin.top + blockPadding.top);

  /// True if the current device is Phone
  bool get isMobile => screenSize.width < 600;
  // TODO: higher res
  bool get isDesktop => screenSize.width > 1000;

  /// True if the current device is Tablet
  bool get isTablet => !isMobile && !isDesktop;

  /// True if the current device is Phone or Tablet
  bool get isMobileOrTablet => isMobile || isTablet;
  Brightness get brightness => MediaQuery.of(this).platformBrightness;
  bool get isDarkMode => brightness == Brightness.dark;
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
  EdgeInsets get blockPadding => const EdgeInsets.symmetric(
      horizontal: Margins.half, vertical: Margins.half);
  EdgeInsets get blockPaddingExtra => const EdgeInsets.symmetric(
      horizontal: Margins.full, vertical: Margins.full);

  // double get blockWidth =>
  //     isMobileOrTablet ? Block.blockWidthSmall : Block.blockWidthLarge;
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
  void showModal(Widget child) {
    showCupertinoModalBottomSheet(
      barrierColor: backgroundColor.withOpacity(0.5),
      context: this,
      expand: false,
      useRootNavigator: true,
      builder: (context) => Material(
        color: context.surfaceColor,
        child: SafeArea(child: child),
      ),
    );
  }
}

extension ConstantsExt on BuildContext {
  Widget get sendIcon => Icon(Icons.send, color: onSurfaceColor);
  Widget get deliveredIcon => Icon(Icons.receipt, color: primaryColor);

  double get iconSizeSmall => IconSize.small;
  double get iconSizeProfile => IconSize.profile;
  double get iconSizeStandard => IconSize.standard;
  double get iconSizeLarge => IconSize.large;
  double get iconSizeXL => IconSize.xl;
}

extension TextExt on BuildContext {
  // TODO: overriding this here and not using from theme
  TextStyle get d =>
      TextStyle(fontSize: 24, color: primaryColor, fontFamily: "Hackney");
  // Theme.of(this).textTheme.displayLarge!;
  TextStyle get h1 => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get h2 => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get h3 => Theme.of(this).textTheme.headlineSmall!;
  TextStyle get m => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get s => Theme.of(this).textTheme.bodySmall!;
  TextStyle get l => Theme.of(this).textTheme.bodyLarge!;
}
