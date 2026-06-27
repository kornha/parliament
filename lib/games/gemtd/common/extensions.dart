import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

import 'components/loading_item.dart';

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

extension ThemeExt on BuildContext {
  TextTheme get primaryTextTheme => Theme.of(this).primaryTextTheme;

  // TextTheme get accentTextTheme => Theme.of(this).accentTextTheme;

  ThemeData get themeData => Theme.of(this);

  BottomAppBarThemeData get bottomAppBarTheme => Theme.of(this).bottomAppBarTheme;

  BottomSheetThemeData get bottomSheetTheme => Theme.of(this).bottomSheetTheme;

  Color get backgroundColor => isDarkMode ? Palette.black : Palette.white;

  Color get foregroundColor => isDarkMode ? Palette.white : Palette.black;

  Color get foregroundColorTansluscent =>
      isDarkMode ? Palette.whiteTransluscent : Palette.blackTransluscent;

  Color get backgroundColorTansluscent =>
      isDarkMode ? Palette.blackTransluscent : Palette.whiteTransluscent;

  LinearGradient get foregroundGradient =>
      isDarkMode ? Palette.whiteGradient : Palette.blackGradient;

  Color get primaryColor => backgroundColor;

  Color get secondaryColor => foregroundColor;

  // Color get buttonColor => Theme.of(this).buttonColor;

  Color get scaffoldBackgroundColor => Theme.of(this).scaffoldBackgroundColor;

  Color get slate => isDarkMode ? Palette.darkSlate : Palette.lightSlate;

  AppBarThemeData get appBarTheme => Theme.of(this).appBarTheme;

  TargetPlatform get platform => Theme.of(this).platform;

  bool get isAndroid => this.platform == TargetPlatform.android;

  bool get isIOS => this.platform == TargetPlatform.iOS;

  bool get isMacOS => this.platform == TargetPlatform.macOS;

  bool get isWindows => this.platform == TargetPlatform.windows;

  bool get isFuchsia => this.platform == TargetPlatform.fuchsia;

  bool get isLinux => this.platform == TargetPlatform.linux;
}

extension ScaffoldExt on BuildContext {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
          SnackBar snackbar) =>
      ScaffoldMessenger.of(this).showSnackBar(snackbar);

  void removeCurrentSnackBar(
          {SnackBarClosedReason reason = SnackBarClosedReason.remove}) =>
      ScaffoldMessenger.of(this).removeCurrentSnackBar(reason: reason);

  void hideCurrentSnackBar(
          {SnackBarClosedReason reason = SnackBarClosedReason.hide}) =>
      ScaffoldMessenger.of(this).hideCurrentSnackBar(reason: reason);

  void openDrawer() => Scaffold.of(this).openDrawer();

  void openEndDrawer() => Scaffold.of(this).openEndDrawer();

  void showBottomSheet(WidgetBuilder builder,
          {Color? backgroundColor,
          double? elevation,
          ShapeBorder? shape,
          Clip? clipBehaviour}) =>
      Scaffold.of(this).showBottomSheet(builder,
          backgroundColor: backgroundColor,
          elevation: elevation,
          shape: shape,
          clipBehavior: clipBehaviour);
}

extension Modal on BuildContext {
  void showModal(List<Widget> widgets) {
    showModalBottomSheet(
      context: this,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(10.0),
      // ),
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -1),
                color: foregroundColorTansluscent,
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          padding: isMobile ? pfh : pf3,
          // TODO: Need to set MediaQuery here to get correct Brightness
          // This is for landing screen setting the brightness
          // Possible this leads to bugs/performance, need to confirm
          child: MediaQuery(
            data: mediaQueryData,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: isMobile
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  // "Drag" thingy
                  child: Container(
                    height: 6,
                    width: 40,
                    decoration: BoxDecoration(
                      color: foregroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                sh,
                ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: widgets.length,
                    itemBuilder: (_, i) {
                      return widgets[i];
                    }),
                sq,
              ],
            ),
          ),
        );
      },
    );
  }

  showLoading({String text = 'Loading...'}) {
    showDialog(
      context: this,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [sf, const LoadingItem()],
            ),
          ),
        );
      },
    );
  }

  hideLoading() {
    Navigator.of(this).pop();
  }
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

  EdgeInsets get pl => const EdgeInsets.symmetric(
      horizontal: Margins.least, vertical: Margins.least);

  EdgeInsets get pz => const EdgeInsets.all(0);

  EdgeInsets get mf => const EdgeInsets.symmetric(
      horizontal: Margins.full, vertical: Margins.full);

  EdgeInsets get mh => const EdgeInsets.symmetric(
      horizontal: Margins.half, vertical: Margins.half);

  EdgeInsets get mz => const EdgeInsets.all(0);

  EdgeInsets get blockMargin => const EdgeInsets.fromLTRB(
      Margins.half, Margins.full, Margins.half, Margins.full);

  EdgeInsets get blockPadding => isMobile
      ? const EdgeInsets.all(Margins.full)
      : isTablet
          ? const EdgeInsets.all(Margins.threeHalf)
          : const EdgeInsets.symmetric(
              horizontal: Margins.twice, vertical: Margins.threeHalf);

  double get blockWidth =>
      isMobileOrTablet ? Block.blockWidthSmall : Block.blockWidthLarge;

  SizedBox get st =>
      const SizedBox(height: Margins.triple, width: Margins.triple);

  SizedBox get sd =>
      const SizedBox(height: Margins.twice, width: Margins.twice);

  SizedBox get sf => const SizedBox(height: Margins.full, width: Margins.full);

  SizedBox get sh => const SizedBox(height: Margins.half, width: Margins.half);

  SizedBox get sq =>
      const SizedBox(height: Margins.quarter, width: Margins.quarter);

  SizedBox get sl =>
      const SizedBox(height: Margins.least, width: Margins.least);
}

extension Sizing on BuildContext {
  Vector2 get popoverSize =>
      Vector2(min(GameConstants().screenSize.x * .6, 500), 250);

  Vector2 get arrowSize => Vector2(20, 20);
}

extension TypographyExt on BuildContext {
  // TextStyle get logo => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //         fontSize: 100,
  //         color: foregroundColor,
  //         shadows: const [
  //           Shadow(
  //             color: Color(0x40000000),
  //             offset: Offset(1, 1),
  //             blurRadius: 4,
  //           )
  //         ],
  //         fontWeight: FontWeight.normal,
  //       ),
  //     );

  // TextStyle get w1 => TextStyle(
  //     fontSize: isMobile
  //         ? 55
  //         : isTablet
  //             ? 75
  //             : 100,
  //     color: foregroundColor,
  //     fontFamily: "Hackney");

  // TextStyle get w2 => TextStyle(
  //     fontSize: isMobile
  //         ? 42
  //         : isTablet
  //             ? 46
  //             : 50,
  //     color: foregroundColor,
  //     fontFamily: "Hackney");

  // static const h1SizeL = 28.0;
  // static const h1SizeM = 26.0;
  // static const h1SizeS = 22.0;

  // TextStyle get h1Logo => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //         fontSize: h1SizeL,
  //         color: foregroundColor,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     );

  // TextStyle get h1Alt => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //         fontSize: isMobile
  //             ? h1SizeS
  //             : isTablet
  //                 ? h1SizeM
  //                 : h1SizeL,
  //         color: foregroundColor,
  //         fontWeight: FontWeight.w300,
  //       ),
  //     );

  // TextStyle get h1 => TextStyle(
  //     fontSize: isMobile
  //         ? 30
  //         : isTablet
  //             ? 34
  //             : 36,
  //     color: foregroundColor,
  //     fontWeight: FontWeight.w300,
  //     fontFamily: "Hackney");

  // TextStyle get h2 => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //           fontSize: isMobile
  //               ? 18
  //               : isTablet
  //                   ? 19
  //                   : 20,
  //           color: foregroundColor,
  //           fontWeight: FontWeight.w300),
  //     );

  // TextStyle get h3 => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //           fontSize: 16, color: foregroundColor, fontWeight: FontWeight.w600),
  //     );

  // TextStyle get N => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //           fontSize: 16,
  //           color: foregroundColor,
  //           fontWeight: FontWeight.normal),
  //     );

  // TextStyle get S => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //           fontSize: 12, color: foregroundColor, fontWeight: FontWeight.w300),
  //     );

  // TextStyle get buttonTextStyle => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //         fontSize: 14,
  //         color: foregroundColor,
  //         letterSpacing: 1,
  //       ),
  //     );

  // TextStyle get b1 => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //           fontSize: 18, color: foregroundColor, fontWeight: FontWeight.bold),
  //     );

  // TextStyle get b2 => GoogleFonts.montserrat(
  //       textStyle: TextStyle(
  //           fontSize: 16, color: foregroundColor, fontWeight: FontWeight.bold),
  //     );
}

extension ConstantsEXT on BuildContext {
  double get smallLogoHeight => 32;

  double get mediumLogoHeight => 64;

  double get largeLogoHeight => 75;

  Widget get largeLogo => isMobile
      ? Image.asset(
          "assets/images/skyfall_logo_mono.png",
          height: mediumLogoHeight,
          fit: BoxFit.contain,
          color: foregroundColor,
        )
      : Image.asset(
          "assets/images/icons/skyfall_icon_75x75.png",
          height: largeLogoHeight,
          fit: BoxFit.contain,
          color: foregroundColor,
        );

  BorderSide get standardBorderSide => BorderSide(
      width: Constants.standardBorderWidth, color: foregroundColorTansluscent);

  BorderSide get boldBorderSide =>
      BorderSide(width: Constants.boldBorderWidth, color: foregroundColor);

  Decoration get selectedBorderDecoration => BoxDecoration(
        border: Border.all(color: slate, width: Constants.standardBorderWidth),
        borderRadius: BRadius.standard,
      );

  Decoration get unselectedBorderDecoration => BoxDecoration(
        border: Border.all(
            color: Colors.transparent, width: Constants.standardBorderWidth),
        borderRadius: BRadius.standard,
      );
}

extension ProviderExt on BuildContext {
  // bool get isLoggedIn => Provider.of<AuthState>(this).isLoggedIn;
  // bool get isAuthLoading =>
  //     Provider.of<AuthState>(this).status == AuthStatus.unknown ||
  //     Provider.of<AuthState>(this).status == AuthStatus.authenticating;
  // bool get isLoggedInQuiet =>
  //     Provider.of<AuthState>(this, listen: false).isLoggedIn;
  // ZUser? get zuser => Provider.of<ZUser?>(this);

  // ThemeMode get themeMode => Provider.of<ThemeModel>(this).themeMode;
}

extension ListLevelX<T> on List<T> {
  T getByLevel(int level) => level > length ? last : this[level - 1];
}
