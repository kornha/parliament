import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class Rock extends GemComponent with DoubleTapCallbacks {
  Rock({Vector2? position, bool autobuild = false})
      : super(
            position: position,
            priority: Constants.ROCK_PRIORITY,
            autobuild: autobuild);

  @override
  GemAttributes settings = RockAttributes();

  // Rocks aren't selectable on a single tap; a double tap builds over them.
  @override
  bool onTapDown(TapDownEvent event) => false;

  // The rock sprite is a white block; modulate-tint it to the theme's
  // foreground so blocks read black in light mode (and stay white in dark).
  // Checked per frame so a live theme switch retints existing rocks.
  Color? _tint;

  @override
  void update(double dt) {
    super.update(dt);
    final c = gameRef.blockColor;
    if (_tint != c) {
      _tint = c;
      paint.colorFilter = ColorFilter.mode(c, BlendMode.modulate);
    }
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (gameRef.placeController.placing) {
      gameRef.weaponFactory.tryPlaceGem(position);
    }
  }

  @override
  bool get active => false;

  @override
  // TODO: implement scanable
  bool get scanable => false;

  @override
  // TODO: implement radarOn
  bool get radarOn => false;

  @override
  double get bounty => 0.0;
}

class RockAttributes extends GemAttributes {
  @override
  List<String> names = [
    "Rock",
  ];

  @override
  CityType gemType = CityType.ROCK;

  @override
  int cost = 1;

  @override
  double baseDamage(int level) => 0;

  @override
  double baseRange(int level) => 0;

  @override
  double fireInterval = 0;

  @override
  double baseRotateSpeed = 0;
}
