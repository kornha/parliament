import 'package:flutter/material.dart';

class Palette {
  static const black = Color.fromRGBO(0, 0, 0, 1);
  static const white = Color.fromRGBO(255, 255, 255, 1);

  static const lightSlate = Color.fromARGB(255, 116, 116, 116);
  static const darkSlate = Color.fromARGB(255, 57, 57, 57);

  static const burntRed = Color.fromRGBO(255, 45, 45, 1);
  static const red = Color.fromRGBO(255, 0, 0, 1);
  static const green = Color.fromRGBO(0, 255, 0, 1);
  static const blue = Color.fromRGBO(0, 0, 255, 1);
  static const burnBlue = Color.fromRGBO(21, 21, 255, 1);
  static const purple = Color.fromRGBO(255, 0, 255, 1);
}

class ThemeConstants {
  static final darkTheme = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: Palette.white,
      onPrimary: Palette.blue,
      secondary: Palette.red,
      onSecondary: Palette.green,
      error: Palette.red,
      onError: Palette.red,
      background: Palette.black,
      onBackground: Palette.lightSlate,
      surface: Palette.darkSlate,
      onSurface: Palette.burnBlue,
    ),
    brightness: Brightness.dark,
  );

  static final lightTheme = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Palette.black,
      onPrimary: Palette.blue,
      secondary: Palette.red,
      onSecondary: Palette.green,
      error: Palette.red,
      onError: Palette.red,
      background: Palette.white,
      onBackground: Palette.darkSlate,
      surface: Palette.lightSlate,
      onSurface: Palette.burnBlue,
    ),
    // highlightColor: Colors.transparent,
    // splashColor: Colors.transparent,
    // hoverColor: Colors.transparent,
    // unselectedWidgetColor: Palette.lightSlate,
    // textTheme: const TextTheme()
    //     .apply(bodyColor: Palette.black, displayColor: Palette.black),
    brightness: Brightness.light,
  );
}
