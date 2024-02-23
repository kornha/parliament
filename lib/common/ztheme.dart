import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:political_think/common/chat/flutter_chat_ui.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/constants.dart';

class ZTheme {
  static final darkTheme = ThemeData(
    splashColor: Colors.transparent,
    canvasColor: Colors.transparent,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Palette.white,
      onPrimary: Palette.black,
      secondary: Palette.green,
      onSecondary: Palette.black,
      error: Palette.purple,
      onError: Palette.black,
      background: Palette.black,
      onBackground: Palette.blue,
      surface: Palette.darkSlate,
      onSurface: Palette.white, // SAME IN LIGHT AND DARK
    ),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Colors.red,
    ),
    textTheme: GoogleFonts.newsreaderTextTheme().apply(
      bodyColor: Palette.white,
      displayColor: Palette.white,
    ),
    fontFamily: GoogleFonts.newsreader().fontFamily,
    brightness: Brightness.dark,
  );

  static final lightTheme = ThemeData(
    splashColor: Colors.transparent,
    canvasColor: Colors.transparent,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Palette.black,
      onPrimary: Palette.white,
      secondary: Palette.green,
      onSecondary: Palette.black,
      error: Palette.purple,
      onError: Palette.black,
      background: Palette.white,
      onBackground: Palette.blue,
      surface: Palette.lightSlate,
      onSurface: Palette.white, // SAME IN LIGHT AND DARK
    ),
    inputDecorationTheme: const InputDecorationTheme(
      fillColor: Colors.red,
    ),

    textTheme: GoogleFonts.newsreaderTextTheme(),
    fontFamily: GoogleFonts.newsreader().fontFamily,
    // highlightColor: Colors.transparent,
    // splashColor: Colors.transparent,
    // hoverColor: Colors.transparent,
    // unselectedWidgetColor: Palette.lightSlate,
    // textTheme: const TextTheme()
    //     .apply(bodyColor: Palette.black, displayColor: Palette.black),
    brightness: Brightness.light,
  );

  // ///////////////////////////
  // Chat
  // ///////////////////////////

  // coupled with our chat library
  static final darkChatTheme = DefaultChatTheme(
    backgroundColor: darkTheme.colorScheme.background,
    errorColor: darkTheme.colorScheme.error,
    primaryColor: darkTheme.colorScheme.secondary,
    secondaryColor: darkTheme.colorScheme.primary,
    inputBackgroundColor: darkTheme.colorScheme.background,
    inputTextColor: darkTheme.colorScheme.primary,
    inputTextCursorColor: darkTheme.colorScheme.secondary,
    sendingIcon: const Loading(type: LoadingType.profile),
    // TODO: Hack, semi-random values
    sendButtonMargin:
        const EdgeInsets.only(right: Margins.threeQuarter, left: Margins.half),
    sendButtonIcon: Icon(
      size: IconSize.standard,
      FontAwesomeIcons.chevronRight,
      color: darkTheme.colorScheme.secondary,
    ),
    inputPadding: const EdgeInsets.symmetric(
      horizontal: Margins.full,
      vertical: Margins.full,
    ),
    statusIconPadding: const EdgeInsets.all(0),
    inputMargin: const EdgeInsets.symmetric(horizontal: Margins.half),
    inputContainerDecoration: BoxDecoration(
      color: darkTheme.colorScheme.background,
      borderRadius: BRadius.standard,
      border: Border.all(
        color: darkTheme.colorScheme.surface,
        width: 0.5,
      ),
    ),
  );

  static final lightChatTheme = DefaultChatTheme(
    backgroundColor: lightTheme.colorScheme.background,
    errorColor: lightTheme.colorScheme.error,
    primaryColor: lightTheme.colorScheme.secondary,
    secondaryColor: lightTheme.colorScheme.primary,
    inputBackgroundColor: lightTheme.colorScheme.background,
    inputTextColor: lightTheme.colorScheme.primary,
    inputTextCursorColor: lightTheme.colorScheme.secondary,
    sendingIcon: const Loading(type: LoadingType.profile),
    // TODO: Hack, semi-random values
    sendButtonMargin:
        const EdgeInsets.only(right: Margins.threeQuarter, left: Margins.half),
    sendButtonIcon: Icon(
      size: IconSize.standard,
      FontAwesomeIcons.chevronRight,
      color: lightTheme.colorScheme.secondary,
    ),
    inputPadding: const EdgeInsets.symmetric(
      horizontal: Margins.full,
      vertical: Margins.full,
    ),
    statusIconPadding: const EdgeInsets.all(0),
    inputMargin: const EdgeInsets.symmetric(horizontal: Margins.half),
    inputContainerDecoration: BoxDecoration(
      color: lightTheme.colorScheme.background,
      borderRadius: BRadius.standard,
      border: Border.all(
        color: lightTheme.colorScheme.surface,
        width: 0.5,
      ),
    ),
  );
}
