// import 'dart:math';
//
// import 'package:flame/components.dart';
// import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
// import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/gems/mena/mena.dart';
// import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
//
// import '../tech.dart';
//
// class WhatsApp extends GemComponent {
//   WhatsApp({Vector2? position, bool hidden = false})
//       : super(position: position, hideSprite: hidden);
//
//   @override
//   GemAttributes settings = WhatsAppSettings();
//
//   @override
//   Future<void>? onLoad() async {
//     await super.onLoad();
//   }
// }
//
// class WhatsAppSettings extends GemAttributes {
//   @override
//   CityType gemType = CityType.MENA;
//
//   final _base = Tech()..level = 3;
//   @override
//   List<String> names = [
//     "WhatsApp",
//   ];
//
//   @override
//   String name(int level) => names[0];
//
//   @override
//   double baseDamage(int level) => _base.settings.baseDamage(level);
//
//   @override
//   double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
//
//   @override
//   double baseRange(int level) => _base.settings.baseRange(level);
//
//   @override
//   String get projectilePath => "weapon/tech_bullet_pink.png";
//
//   @override
//   double get projectileSizeX => _base.settings.projectileSizeX;
//
//   @override
//   double get projectileSizeY => _base.settings.projectileSizeY;
//
//   @override
//   int projectileColumns(level) => _base.settings.projectileColumns(level);
//
//   @override
//   int projectileRows(level) => _base.settings.projectileRows(level);
//
//   @override
//   int get explosionColumns => _base.settings.explosionColumns;
//
//   @override
//   int get explosionRows => _base.settings.explosionRows;
//
//   @override
//   String get explosionImage => "weapon/tech_explosion_pink.png";
//
//   @override
//   double get explosionSizeX => _base.settings.explosionSizeX;
//
//   @override
//   double get explosionSizeY => _base.settings.explosionSizeY;
//
//   @override
//   double get explosionStepTime => _base.settings.explosionStepTime;
//
//   @override
//   bool get canHitIntermediateTargets =>
//       _base.settings.canHitIntermediateTargets;
//
//   @override
//   Set<Ability> abilities(int level, GemComponent caster) => {
//         Tether(level: _base.level, caster: caster),
//         MultiAttack(level: _base.level, caster: caster),
//       };
// }
