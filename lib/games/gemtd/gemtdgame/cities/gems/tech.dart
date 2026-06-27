// import 'dart:math';
//
// import 'package:flame/components.dart';
// import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
// import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
//
// class Tech extends GemComponent {
//   Tech({Vector2? position, bool hidden = false})
//       : super(position: position, hideSprite: hidden);
//
//   @override
//   GemAttributes settings = TechSettings();
//
//   @override
//   Future<void>? onLoad() async {
//     await super.onLoad();
//   }
// }
//
// class TechSettings extends GemAttributes {
//   @override
//   CityType gemType = CityType.WEUROPE;
//   // ebay
//   @override
//   List<String> names = [
//     "IBM", // Coinbase
//     "Microsoft", // Boeing
//     "Amazon", // Boeing
//     "Meta", // WhatsApp
//     "Google", // TripAdvisor
//     "Apple",
//   ];
//
//   @override
//   double baseDamage(int level) => 0.56 + level * 0.3;
//
//   @override
//   double baseAttackSpeed(int level) => 2.85 + level * 0.28;
//
//   @override
//   double baseRange(int level) => 3;
//
//   @override
//   String get projectilePath => "weapon/tech_bullet.png";
//
//   @override
//   double projectileSizeX = 0.2;
//
//   @override
//   double projectileSizeY = 0.48;
//
//   @override
//   int projectileRows(level) => 1;
//
//   @override
//   int projectileColumns(level) => 1;
//
//   @override
//   // TODO: implement explosionColumns
//   int get explosionColumns => 1;
//
//   @override
//   // TODO: implement explosionRows
//   int get explosionRows => 1;
//
//   @override
//   // TODO: implement explosionImage
//   String get explosionImage => "weapon/tech_explosion.png";
//
//   @override
//   double get explosionSizeX => 1.6;
//
//   @override
//   double get explosionSizeY => 1.6;
//
//   @override
//   double get explosionStepTime => 0.04;
//
//   @override
//   bool get canHitIntermediateTargets => false;
//
//   @override
//   Set<Ability> abilities(int level, GemComponent caster) => {
//         Tether(level: level, caster: caster),
//       };
// }
