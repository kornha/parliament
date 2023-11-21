import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/room.dart';
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
  ZUser user() => read(zuserProvider(authRead.authUser!.uid)).value!;
  AsyncValue<Post?> postWatch(String pid) => watch(postProvider(pid));
  AsyncValue<Post?> postRead(String pid) => read(postProvider(pid));
  AsyncValue<Room?> roomWatch(String uid, String pid) =>
      watch(roomProvider((uid, pid)));
  AsyncValue<Room?> roomRead(String uid, String pid) =>
      read(roomProvider((uid, pid)));

  AsyncValue<List<ct.Message>?> messagesWatch(String rid, int limit) =>
      watch(messagesProvider((rid, limit)));
  refreshMessages(String rid, int limit) =>
      refresh(messagesProvider((rid, limit)));
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
      horizontal: Margins.full, vertical: Margins.half);
  EdgeInsets get blockPadding => const EdgeInsets.symmetric(
      horizontal: Margins.full, vertical: Margins.half);

  double get blockWidth =>
      isMobileOrTablet ? Block.blockWidthSmall : Block.blockWidthLarge;
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
  Widget get sendIcon => Icon(Icons.send, color: primaryColor);
  Widget get deliveredIcon => Icon(Icons.receipt, color: primaryColor);
}

extension TextExt on BuildContext {
  TextStyle get DL => Theme.of(this).textTheme.displayLarge!;
  TextStyle get DM => Theme.of(this).textTheme.displayMedium!;
  TextStyle get DS => Theme.of(this).textTheme.displaySmall!;
  TextStyle get HL => Theme.of(this).textTheme.headlineLarge!;
  TextStyle get HM => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get HS => Theme.of(this).textTheme.headlineSmall!;
  TextStyle get BM => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get BS => Theme.of(this).textTheme.bodySmall!;
  TextStyle get BL => Theme.of(this).textTheme.bodyLarge!;
}
