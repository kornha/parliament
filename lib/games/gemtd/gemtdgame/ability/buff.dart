import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:quiver/core.dart';

import 'ability.dart';

enum RenderType { GRID, TOPRIGHT, BOTLEFT, TOPCENTER, NONE }

enum DurationType { TICK, ATTACK }

// Note! Ability stack types require only 1 level of ability to exist
enum StackType { CASTER, BUFF_LEVEL, BUFF }

abstract class Buff {
  Buff({
    required this.caster,
    required this.level,
  }) {
    duration = baseDuration;
  }

  //
  abstract String name;
  abstract String description;
  abstract IconData icon;
  abstract CityType gemType;

  Color get color => gemType.color();

  //
  GemComponent caster;

  //
  int level;

  double? get baseDuration;

  DurationType get durationType => DurationType.TICK;

  //
  StackType get stackType => StackType.CASTER;

  //
  //enemy
  double? get damage => null;

  double? speedModifier(EnemyComponent enemy) => null;

  double? receiveDamageMultiplier(EnemyComponent enemy) => null;

  double? armorModifier(EnemyComponent enemy) => null;

  double? duration = 0;

  int? stacks;

  // both
  double? bountyMultiplier;

  //ally
  double? rangeDelta;
  double? rangeMultiplier;
  double? damageMultiplier;
  double? attackSpeedMultiplier;
  double? buffMultiplier;
  double? chanceMultiplier;
  double? bountyDamageScalar;

  //
  RenderType renderType = RenderType.NONE;

  // Size of the on-board buff indicator glyph (override per-buff if needed).
  double get iconFontSize => 9;

  //
  void render(Canvas c, Offset o, [GameComponent? component]) {
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: color,
        fontFamily: icon.fontFamily,
        fontSize: iconFontSize,
        package:
            icon.fontPackage, // This line is mandatory for external icon packs
      ),
    );
    textPainter.layout();
    o = Offset(o.dx - textPainter.width, o.dy - textPainter.height);
    textPainter.paint(c, o);
  }

  void resetDuration() {
    duration = baseDuration;
  }

  // returns whether or not bullet should finish move
  bool bulletDidHitEnemy(BulletComponent bullet, EnemyComponent enemy) => true;

  @override
  bool operator ==(other) {
    switch (stackType) {
      case StackType.CASTER:
        return other is Buff &&
            name == other.name &&
            level == other.level &&
            caster == other.caster;
      case StackType.BUFF_LEVEL:
        return other is Buff && name == other.name && level == other.level;
      case StackType.BUFF:
        return other is Buff && name == other.name;
    }
  }

  @override
  int get hashCode {
    switch (stackType) {
      case StackType.CASTER:
        return hash3(name.hashCode, level.hashCode, caster);
      case StackType.BUFF_LEVEL:
        return hash2(name.hashCode, level.hashCode);
      case StackType.BUFF:
        return name.hashCode;
    }
  }

  static onEnemyRemoved(EnemyComponent enemy) {
    Religion.renderNumbers.remove(enemy);
  }

  static onWaveComplete() {
    Religion.renderNumbers.clear();
  }

  static Set<Buff> getFiringBuffs(Set<Ability> abilities, GemComponent gem) {
    Set<Buff> buffs = {};
    // we need to split this since element.buff is a function
    // and can sometimes return null on different calls when
    // Random() is involved
    abilities.forEach((ability) {
      var buff = ability.buff;
      if (buff != null && ability.worksOnEnemies) {
        // We scale enemy duration buffs here, which might be hacky!
        // other buffs scaled in status_manager
        if (buff.duration != null) {
          buff.duration = buff.duration! * gem.currentBuffMultiplier;
        }
        buffs.add(buff);
      }
    });
    return buffs;
  }
}

class Burn extends Buff {
  Burn({required super.caster, required super.level});

  @override
  String name = "Burn";

  @override
  String description = "Damages enemies over time.";

  static var damagePerLevel = [1.5, 2.25, 3.0, 3.75, 4.5, 10.0, 20.0];

  @override
  double? get damage => damagePerLevel.getByLevel(level);

  @override
  IconData icon = Icons.whatshot;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  double? baseDuration = 3;
}

class ColombianRoast extends Buff {
  ColombianRoast({required super.caster, required super.level});

  @override
  String name = "Colombian Roast";

  @override
  String description = "Stacking burn damage.";

  static const damagePerStack = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75];

  @override
  double? get damage => damagePerStack.getByLevel(level) * (stacks ?? 1);

  @override
  int? stacks = 1;

  @override
  IconData icon = FontAwesomeIcons.fireFlameCurved.data;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  double? baseDuration = 3;

  @override
  RenderType get renderType => RenderType.GRID;
}

class Inti extends Buff {
  Inti({required super.caster, required super.level});

  @override
  String name = "Inti";

  @override
  String description = "Enemies take increased damage from all sources.";

  static const multiplierPerLevel = <double>[0.10, 0.15, 0.20, 0.25, 0.30, 0.35];

  @override
  double? receiveDamageMultiplier(EnemyComponent enemy) =>
      multiplierPerLevel.getByLevel(level);

  @override
  IconData icon = FontAwesomeIcons.sun.data;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  double? baseDuration = 2;

  @override
  RenderType get renderType => RenderType.GRID;
}

class Asado extends Buff {
  Asado({required super.caster, required super.level});

  @override
  String name = "Asado";

  @override
  String description = "Escalating burn damage.";

  static const baseDamagePerLevel = <double>[1.0, 1.5, 2.0, 2.5, 3.0, 3.5];
  static const escalationPerLevel = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75];

  double get elapsed => (baseDuration ?? 0) - (duration ?? 0);

  @override
  double? get damage =>
      baseDamagePerLevel.getByLevel(level) +
      escalationPerLevel.getByLevel(level) * elapsed;

  @override
  IconData icon = FontAwesomeIcons.fireFlameSimple.data;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  double? baseDuration = 4;

  @override
  RenderType get renderType => RenderType.GRID;
}

class Furnace extends Buff {
  Furnace({required super.caster, required super.level});

  @override
  String name = "Furnace";

  @override
  String description = "Strips armor from burning enemies.";

  static const durationPerLevel = <double>[1.5, 1.7, 1.9, 2.1, 2.3, 2.5];

  @override
  double? armorModifier(EnemyComponent enemy) {
    if (enemy.buffs.any((b) => b is Burn)) {
      return enemy.settings.baseArmor(enemy.level);
    }
    return null;
  }

  @override
  IconData icon = FontAwesomeIcons.industry.data;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  double? get baseDuration => durationPerLevel.getByLevel(level);

  @override
  RenderType get renderType => RenderType.GRID;
}

class Lust extends Buff {
  Lust({required super.caster, required super.level});

  @override
  String name = "Lust";

  @override
  String description = "Damages enemies over time.";

  static final List<double> reductionPerLevel = [6, 10, 14, 18, 22, 40];

  @override
  double? armorModifier(EnemyComponent enemy) =>
      reductionPerLevel.getByLevel(level);

  @override
  IconData icon = FontAwesomeIcons.peace.data;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  double? baseDuration = 3;
}

class BountyMultiple extends Buff {
  static const defaultMultipliers = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75];

  BountyMultiple({
    required super.caster,
    required super.level,
    this.multipliersPerLevel = defaultMultipliers,
    this.overrideMultiplier,
    this.overrideBaseDuration, // null by default means will not expire
  });

  final List<double> multipliersPerLevel;
  double? overrideMultiplier;

  double? overrideBaseDuration;

  @override
  double get bountyMultiplier =>
      overrideMultiplier ?? multipliersPerLevel.getByLevel(level);

  @override
  String name = "Bounty Multiple";

  @override
  String description =
      "Increases or decreases the bounty cities or enemies with this buff.";

  @override
  IconData icon = FontAwesomeIcons.coins.data;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  double? get baseDuration => overrideBaseDuration;
}

class Poison extends Buff {
  Poison({required super.caster, required super.level});

  @override
  String name = "Spice Route";

  @override
  String description = "Spices slow and damage enemies over time.";

  static var damagePerLevel = [1.3, 1.8, 2.3, 2.8, 3.3, 6.6];

  @override
  double? get damage => damagePerLevel.getByLevel(level);

  @override
  IconData icon = Icons.sick_outlined;

  static var slowPerLevel = [0.15, 0.20, 0.25, 0.30, 0.35, 0.5];

  @override
  double? speedModifier(EnemyComponent enemy) =>
      slowPerLevel.getByLevel(level);

  @override
  CityType gemType = CityType.SASIA;

  @override
  double? baseDuration = 3;
}

// Addis Ababa (Africa) — a pure poison DoT (no slow; the region already has
// plenty of slows).
class VenomBuff extends Buff {
  VenomBuff({required super.caster, required super.level});

  @override
  String name = "Venom";

  @override
  String description = "Poisoned — taking damage over time.";

  static var damagePerLevel = [2.0, 3.0, 4.0, 5.0, 6.0, 12.0];

  @override
  double? get damage => damagePerLevel.getByLevel(level);

  @override
  IconData icon = Icons.sick_outlined;

  @override
  CityType gemType = CityType.AFRICA;

  @override
  double? baseDuration = 4;

  @override
  RenderType get renderType => RenderType.GRID;
}

class Petronas extends Buff {
  Petronas({required super.caster, required super.level});

  @override
  String name = "Petronas";

  @override
  String description = "Slows enemies.";

  static var slowPerLevel = [0.20, 0.25, 0.3, 0.35, 0.4, 0.45];

  @override
  double? speedModifier(EnemyComponent enemy) =>
      slowPerLevel.getByLevel(level);

  @override
  double? baseDuration = 3;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  IconData icon = Icons.oil_barrel;
}

class Disruption extends Buff {
  static const reductionPerLevel = <double>[1.5, 3, 6, 12, 24];

  Disruption({required super.caster, required super.level});

  @override
  String name = "Disruption";

  @override
  String description = "Reduces an enemy's armor.";

  @override
  IconData icon = Icons.broken_image;

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? armorModifier(EnemyComponent enemy) =>
      reductionPerLevel.getByLevel(level);

  @override
  double? baseDuration = 3;
}

class CriticalStrike extends Buff {
  CriticalStrike({
    required super.caster,
    required super.level,
    this.overrideDamageMultiplier,
  });

  double? overrideDamageMultiplier;

  @override
  String name = "Critical Strike";

  @override
  String description = "Increases the damage of the next attack.";

  @override
  RenderType get renderType => RenderType.TOPRIGHT;

  @override
  IconData icon = Icons.stadium;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  DurationType get durationType => DurationType.ATTACK;

  @override
  double? baseDuration = 1.0;

  static List<double> damageMultiples = [1.5, 1.75, 2, 2.25, 2.5, 3.0];

  @override
  double? get damageMultiplier =>
      overrideDamageMultiplier ?? damageMultiples.getByLevel(level);

  @override
  void render(Canvas c, Offset o, [GameComponent? component]) {
    if (damageMultiplier == null) return;
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: "${damageMultiplier!.toStringAsFixed(1)}x",
      style: TextConstants.hackney,
    );
    textPainter.layout();

    o = Offset(o.dx - textPainter.width, o.dy);
    textPainter.paint(c, o);
  }
}

class ManufacturedTechnology extends Buff {
  ManufacturedTechnology({required super.caster, required super.level});

  @override
  String name = "Manufactured Technology";

  @override
  String description =
      "Increases attack range and causes all chance abilities to cast 100% of the time."
      "\nReduces attack damage, and all debuff durations by 95%.";

  @override
  IconData icon = Icons.copy_all;

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? baseDuration = 1.0;

  static List<double> fraction = [8.0, 8.25, 8.5, 8.75, 9, 9.5];

  @override
  double? get damageMultiplier => 1 / fraction.getByLevel(level);

  @override
  double? get attackSpeedMultiplier => fraction.getByLevel(level);

  @override
  double? get buffMultiplier => 0.05;

  @override
  double? get chanceMultiplier => 100.0;

  @override
  void render(Canvas c, Offset o, [GameComponent? component]) {
    if (damageMultiplier == null) return;
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: "${damageMultiplier!.toString()}x",
      style: TextConstants.hackney,
    );
    textPainter.layout();

    o = Offset(o.dx - textPainter.width, o.dy);
    textPainter.paint(c, o);
  }
}

class Stun extends Buff {
  Stun({required super.caster, required super.level, this.overrideDuration});

  double? overrideDuration;

  @override
  String name = "Stun";

  @override
  RenderType get renderType => RenderType.GRID;

  @override
  String description = "Enemy cannot move.";

  @override
  IconData icon = Icons.block;

  @override
  double? speedModifier(enemy) => 1;

  static var durationPerLevel = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5];

  @override
  double? get baseDuration =>
      overrideDuration ?? durationPerLevel.getByLevel(level);

  @override
  CityType gemType = CityType.EASIA;
}

class Hex extends Buff {
  Hex({required super.caster, required super.level, this.overrideDuration});

  double? overrideDuration;

  @override
  String name = "Hex";

  @override
  RenderType get renderType => RenderType.GRID;

  @override
  String description = "Transformed into a critter.";

  @override
  IconData icon = FontAwesomeIcons.frog.data;

  @override
  double? speedModifier(enemy) => 1;

  static var durationPerLevel = [0.7, 0.9, 1.1, 1.3, 1.5, 1.7];

  @override
  double? get baseDuration =>
      overrideDuration ?? durationPerLevel.getByLevel(level);

  @override
  CityType gemType = CityType.SASIA;
}

// Aura
class Telescope extends Buff {
  static const rangePerLevel = [1.2, 1.5, 1.8, 2.1, 2.4, 2.7];

  Telescope({required super.caster, required super.level});

  @override
  String name = "Telescope";

  @override
  String description = "Increases the range of nearby gems.";

  @override
  IconData icon = Icons.radar;

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? get rangeDelta => rangePerLevel.getByLevel(level);

  @override
  bool worksOnEnemies = false;

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.NONE;
}

class DamageMultiple extends Buff {
  static const defaultMultipliers = [1.2, 1.4, 1.6, 1.8, 2.0, 2.2];

  DamageMultiple({
    required super.caster,
    required super.level,
    this.multipliersPerLevel = defaultMultipliers,
    this.overrideMultiplier,
  });

  final List<double> multipliersPerLevel;
  double? overrideMultiplier;

  @override
  String name = "Damage Multiple";

  @override
  String description = "Increases or decreases the the damage output.";

  @override
  IconData icon = Icons.multiline_chart_rounded;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  double get damageMultiplier =>
      overrideMultiplier ?? multipliersPerLevel.getByLevel(level);

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.NONE;
}

class SequentialAttack extends Buff {
  static const attacksNumPerLevelDefault = [2, 3, 4, 5, 6];
  static const attackSpeedMultiplierDefault = 10.0;
  static final iconDefault = FontAwesomeIcons.arrowsTurnToDots.data;

  SequentialAttack({
    required super.caster,
    required super.level,
    this.attacksNumPerLevel = attacksNumPerLevelDefault,
  });

  final List<int> attacksNumPerLevel;

  int get attacksNum => attacksNumPerLevel.getByLevel(level);

  @override
  String name = "Sequential Attack";

  @override
  String description =
      "Multiple attacks in immediate secession, followed by the regular cool-down.";

  @override
  IconData icon = iconDefault;

  @override
  CityType gemType = CityType.ASEAN;

  late var _fireCountStartValue = caster.fireCount;

  @override
  double? get attackSpeedMultiplier {
    final buffFireCount = caster.fireCount - _fireCountStartValue;
    if (buffFireCount > 0 && (buffFireCount + 1) % attacksNum == 0) {
      resetDuration();
      return null;
    } else {
      return attackSpeedMultiplierDefault;
    }
  }

  void reset() {
    _fireCountStartValue = caster.fireCount;
    resetDuration();
  }

  @override
  late double? baseDuration = attacksNum.toDouble();

  @override
  DurationType durationType = DurationType.ATTACK;
}

class AttackSpeedMultiple extends Buff {
  static const defaultMultipliers = <double>[1.2, 1.4, 1.6, 1.8, 2, 2.2];

  AttackSpeedMultiple({
    required super.caster,
    required super.level,
    this.multipliersPerLevel = defaultMultipliers,
    this.overrideMultiplier,
    this.overrideDurationType,
  });

  final List<double> multipliersPerLevel;
  double? overrideMultiplier;

  DurationType? overrideDurationType;

  @override
  String name = "Attack Speed Multiple";

  @override
  String description = "Increases the attack speed.";

  @override
  IconData icon = FontAwesomeIcons.boltLightning.data;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  double? get attackSpeedMultiplier =>
      overrideMultiplier ?? multipliersPerLevel.getByLevel(level);

  @override
  bool worksOnEnemies = false;

  @override
  double? baseDuration = 1.0;

  @override
  DurationType get durationType => overrideDurationType ?? DurationType.TICK;

  @override
  RenderType get renderType => RenderType.NONE;
}

class BuffMultiple extends Buff {
  static const defaultMultipliers = [1.05, 1.075, 1.1, 1.125, 1.15, 1.2];

  BuffMultiple({
    required super.caster,
    required super.level,
    this.multipliersPerLevel = defaultMultipliers,
    this.overrideMultiplier,
    this.overrideDurationType,
  });

  final List<double> multipliersPerLevel;
  double? overrideMultiplier;

  DurationType? overrideDurationType;

  @override
  String name = "Attack Speed Multiple";

  @override
  String description = "Increases the attack speed.";

  @override
  IconData icon = FontAwesomeIcons.boltLightning.data;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  double get buffMultiplier =>
      overrideMultiplier ?? multipliersPerLevel.getByLevel(level);

  @override
  bool worksOnEnemies = false;

  @override
  double? baseDuration = 1.0;

  @override
  DurationType get durationType => overrideDurationType ?? DurationType.TICK;

  @override
  RenderType get renderType => RenderType.NONE;
}

class ReceiveDamageMultiple extends Buff {
  static const defaultMultipliers = [0.05, 0.075, 0.1, 0.125, 0.15, 0.2];

  ReceiveDamageMultiple({
    required super.caster,
    required super.level,
    this.multipliersPerLevel = defaultMultipliers,
    this.overrideMultiplier,
    this.overrideBaseDuration, // null by default means will not expire
  });

  final List<double> multipliersPerLevel;
  double? overrideMultiplier;

  double? overrideBaseDuration;

  @override
  double receiveDamageMultiplier(EnemyComponent enemy) =>
      overrideMultiplier ?? multipliersPerLevel.getByLevel(level);

  @override
  String name = "Attack Speed Multiple";

  @override
  String description = "Increases or decreases the attack speed.";

  @override
  IconData icon = FontAwesomeIcons.hurricane.data;

  @override
  CityType gemType = CityType.MENA;

  @override
  double? get baseDuration => overrideBaseDuration;

  @override
  RenderType get renderType => RenderType.GRID;
}

// Enemy Aura
class Religion extends Buff {
  static const damagePerLevel = <double>[4, 4.35, 4.7, 5.05, 5.4, 5.75];

  Religion({required super.caster, required super.level});

  @override
  String name = "Religion";

  @override
  String description = "Damages Enemies.";

  @override
  IconData icon = FontAwesomeIcons.handsPraying.data;

  @override
  double? get damage => damagePerLevel.getByLevel(level);

  @override
  CityType gemType = CityType.MENA;

  @override
  bool worksOnEnemies = true;

  @override
  double? baseDuration = 0.4;

  @override
  RenderType get renderType => RenderType.BOTLEFT;

  static Map<EnemyComponent, double> renderNumbers = {};

  @override
  void render(Canvas c, Offset o, [covariant EnemyComponent? component]) {
    double? val = renderNumbers[component];
    Color color = Palette.menaGreen;
    String str;
    IconData _icon = icon;

    if (val == null) {
      str = "";
    } else if (val > 99999) {
      str = "99+";
      _icon = FontAwesomeIcons.message.data;
      color = Colors.lightBlue;
    } else if (val > 9999) {
      str = (val / 1000).toStringAsFixed(0);
      _icon = FontAwesomeIcons.message.data;
      color = Colors.lightBlue;
    } else if (val > 99) {
      str = (val / 100).toStringAsFixed(0);
      _icon = FontAwesomeIcons.share.data;
      color = Colors.purple;
    } else {
      str = val.toStringAsFixed(0);
      _icon = icon;
      color = Palette.menaGreen;
    }

    if (component != null) {
      var containsSphinx = component.buffs.any((element) => element is Sphinx);
      if (containsSphinx) {
        _icon = Sphinx.static_icon;
      }
    }

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      children: [
        TextSpan(
          text: String.fromCharCode(_icon.codePoint),
          style: TextStyle(
            color: Colors.white,
            background: Paint()
              ..strokeWidth = 7.0
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round,
            fontFamily: icon.fontFamily,
            fontSize: 8,
            package: icon
                .fontPackage, // This line is mandatory for external icon packs
          ),
        ),
        TextSpan(
          text: " " + str,
          style: TextConstants.gemSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            background: Paint()
              ..strokeWidth = 7.0
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round,
          ),
        ),
      ],
    );
    textPainter.layout();
    var o1 = Offset(o.dx, o.dy - textPainter.height);
    textPainter.paint(c, o1);

    // TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    // textPainter.text = TextSpan(
    //   text: String.fromCharCode(icon.codePoint),
    //   style: TextStyle(
    //     color: color,
    //     fontFamily: icon.fontFamily,
    //     fontSize: 15,
    //     package:
    //         icon.fontPackage, // This line is mandatory for external icon packs
    //   ),
    // );
    // textPainter.layout();
    // var o1 = Offset(o.dx - textPainter.width, o.dy - textPainter.height);
    // textPainter.paint(c, o1);

    // var textPainter2 = TextPainter(
    //   text: TextSpan(
    //     text: (333).toStringAsFixed(0),
    //     style: TextConstants.gemSmall.copyWith(color: color),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );
    // textPainter2.layout();
    // var o2 = Offset(o.dx - textPainter.width - textPainter2.width,
    //     o.dy - textPainter2.height);
    // textPainter2.paint(c, o2);
  }
}

class Sphinx extends Buff {
  Sphinx({required super.caster, required super.level});

  @override
  String name = "Sphinx";

  @override
  StackType get stackType => StackType.BUFF_LEVEL;

  @override
  String description = "Reduces enemy armor for each stack of Religion.";

  @override
  IconData icon = static_icon;

  //used as this is rendered in Religion
  static IconData static_icon = FontAwesomeIcons.cat.data;

  @override
  CityType gemType = CityType.MENA;

  @override
  double? baseDuration = 0.4;

  @override
  RenderType get renderType => RenderType.NONE;

  static double divider = 100.0;

  @override
  double? armorModifier(EnemyComponent enemy) =>
      Religion.renderNumbers.containsKey(enemy)
          ? Religion.renderNumbers[enemy]! / divider
          : null;
}

class BlackGold extends Buff {
  BlackGold({required super.caster, required super.level});

  @override
  String name = "Black Gold";

  @override
  String description = "Slows enemies in range.";

  @override
  IconData icon = Icons.oil_barrel;

  @override
  CityType gemType = CityType.MENA;

  static const slowPerLevel = [0.15, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  double? slow(EnemyComponent enemy) => slowPerLevel.getByLevel(level);

  @override
  double? baseDuration = 0.4;

  @override
  RenderType get renderType => RenderType.GRID;
}

class StartupNation extends Buff {
  StartupNation({required super.caster, required super.level});

  @override
  String name = "Startup Nation";

  @override
  String description = "Amplifies the bounty-to-damage scalar of nearby gems.";

  @override
  IconData icon = FontAwesomeIcons.rocket.data;

  @override
  CityType gemType = CityType.MENA;

  static const scalarPerLevel = [1.5, 2.0, 2.5, 3.0, 3.5, 4.0];

  @override
  double? get bountyDamageScalar => scalarPerLevel.getByLevel(level);

  @override
  bool worksOnEnemies = false;

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.NONE;
}

class KPOP extends Buff {
  static const slowPerLevel = <double>[-0.2, -0.25, -0.3, -0.35, -0.4, -0.45];
  static const reductionPerLevel = <double>[2, 4, 6, 8, 10, 12];

  KPOP({required super.caster, required super.level});

  @override
  String name = "K-Pop";

  @override
  RenderType get renderType => RenderType.GRID;

  @override
  String description = "Armor being reduced while movement speed is increased.";

  @override
  IconData icon = FontAwesomeIcons.music.data;

  @override
  double? speedModifier(EnemyComponent enemy) =>
      slowPerLevel.getByLevel(level);

  @override
  double? armorModifier(EnemyComponent enemy) =>
      reductionPerLevel.getByLevel(level);

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? baseDuration = 1.5;
}

class GreatWall extends Buff {
  GreatWall({required super.caster, required super.level});

  @override
  String name = "Great Wall";

  @override
  String description = "Increases attack speed but decreases range.";

  @override
  IconData icon = FontAwesomeIcons.gopuram.data;

  @override
  CityType gemType = CityType.EASIA;

  static List<double> fraction = [8, 8.25, 8.5, 8.75, 9, 9.25];

  @override
  double? get attackSpeedMultiplier => fraction.getByLevel(level);

  @override
  double? get rangeMultiplier => 10 / fraction.getByLevel(level);

  @override
  bool worksOnEnemies = false;

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.NONE;
}

class PeoplesRepublic extends Buff {
  PeoplesRepublic({required super.caster, required super.level});

  @override
  String name = "The People's Republic";

  @override
  String description = "Sets % of all chance abilities to 75%"
      "\nReduces debuff duration by 75%.";

  @override
  IconData icon = FontAwesomeIcons.personMilitaryToPerson.data;

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? get buffMultiplier => 0.25;

  @override
  double? get chanceMultiplier => 8;

  @override
  double? baseDuration = 1.0;

  @override
  // THIS ABILITY CAN ONLY EXIST FOR ONE LEVEL!
  StackType get stackType => StackType.BUFF;

  @override
  RenderType get renderType => RenderType.NONE;
}

class ChainAttack extends Buff {
  ChainAttack(
      {required super.caster, required super.level, required this.range});

  @override
  String name = "Chain Attack";

  @override
  String description = "Bullets bounce to the nearest enemy.";

  @override
  IconData icon = FontAwesomeIcons.recycle.data;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  double? baseDuration = 0.0;

  static List<int> bouncesPerLevel = [1, 2, 3, 4, 5, 6];

  // Specific to this buff
  double range;
  Set<EnemyComponent> hitEnemies = {};
  BulletComponent? _bullet;

  @override
  bool bulletDidHitEnemy(BulletComponent bullet, EnemyComponent enemy) {
    _bullet = bullet;
    if (bouncesPerLevel.getByLevel(level) - hitEnemies.length <= 0) return true;
    hitEnemies.add(enemy);
    //
    _bullet!.radarOn = true;
    _bullet!.radarRange = range * gameSettings.mapTileSize.length;
    _bullet!.radarScanClosest = true;
    _bullet!.radarScanAlert = _radarScanAlert;
    // not sure if this will break other attackers
    _bullet!.enemy.onKilledCallback = null;
    return false;
  }

  _radarScanAlert(GameComponent enemy, Set<GameComponent> targets) {
    _bullet!.setRadar();
    for (var target in targets) {
      //
      if (!hitEnemies.contains(target)) {
        _bullet!.enemy = target as EnemyComponent;
        _bullet!.enemy.onKilledCallback = _bullet!.onEnemyKilled;
        _bullet!.canHitIntermediateTargets = false;
        _bullet!.moveToMovable(target);
        return;
      }
    }
    _bullet!.moveFinish();
  }
}

class ArmorModify extends Buff {
  ArmorModify({
    required super.caster,
    required super.level,
    required this.modifier,
    this.overrideBaseDuration, // null by default means will not expire
  });

  double modifier;

  double? overrideBaseDuration;

  @override
  double armorModifier(enemy) => modifier;

  @override
  String name = "Armor Modify";

  @override
  String description = "Increases or decreases an enemy's armor.";

  @override
  CityType gemType = CityType.WEUROPE;

  @override
  late IconData icon = Icons.stacked_line_chart;

  @override
  double? get baseDuration => overrideBaseDuration;
}

class SpeedModify extends Buff {
  SpeedModify({
    required super.caster,
    required super.level,
    required this.modifier,
    this.overrideBaseDuration, // null by default means will not expire
  });

  double modifier;

  double? overrideBaseDuration;

  @override
  double? speedModifier(EnemyComponent enemy) => modifier;

  @override
  String name = "Speed Modify";

  @override
  String description = "Increases or decreases an enemy's movement speed.";

  @override
  CityType gemType = CityType.WEUROPE;

  @override
  late IconData icon = Icons.stacked_line_chart;

  @override
  double? get baseDuration => overrideBaseDuration;
}

class Pierce extends Buff {
  Pierce({required super.caster, required super.level});

  @override
  String name = "Pierce";

  @override
  String description = "Projectiles pierce through enemies.";

  @override
  IconData icon = FontAwesomeIcons.shieldHalved.data;

  @override
  CityType gemType = CityType.EEUROPE;

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.NONE;

  @override
  bool bulletDidHitEnemy(BulletComponent bullet, EnemyComponent enemy) => false;
}

class LeningradBuff extends Buff {
  LeningradBuff({required super.caster, required super.level});

  @override
  String name = "Leningrad";

  @override
  String description =
      "Boosts nearby towers' damage up to this tower's damage level.";

  @override
  IconData icon = FontAwesomeIcons.arrowUp.data;

  @override
  CityType gemType = CityType.EEUROPE;

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.NONE;

  @override
  double? get damageMultiplier => null;
}

class UprisingBuff extends Buff {
  UprisingBuff({required super.caster, required super.level});

  static const percentagePerLevel = <double>[
    0.01, 0.015, 0.02, 0.025, 0.03, 0.035
  ];

  @override
  String name = "Uprising";

  @override
  String description = "Takes damage as a percentage of max health.";

  @override
  double? get damage => null;

  double damageForEnemy(EnemyComponent enemy) =>
      enemy.maxLife * percentagePerLevel.getByLevel(level);

  @override
  IconData icon = FontAwesomeIcons.handFist.data;

  @override
  CityType gemType = CityType.EEUROPE;

  @override
  double? baseDuration = 3.0;

  @override
  RenderType get renderType => RenderType.GRID;
}

// Cross-region "Oiled" status: slows the enemy AND amplifies the damage it takes
// (so burn/DoT hits harder). Applied by S. America's Crude and MENA's Black Gold.
class Oiled extends Buff {
  Oiled({required super.caster, required super.level});

  static const slowPerLevel = <double>[0.10, 0.13, 0.16, 0.19, 0.22, 0.25];
  static const dmgAmpPerLevel = <double>[0.15, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  String name = "Oiled";

  @override
  String description = "Slowed and takes amplified damage.";

  @override
  IconData icon = Icons.oil_barrel;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  double? speedModifier(EnemyComponent enemy) => slowPerLevel.getByLevel(level);

  @override
  double? receiveDamageMultiplier(EnemyComponent enemy) =>
      dmgAmpPerLevel.getByLevel(level);

  @override
  double? baseDuration = 3;

  @override
  RenderType get renderType => RenderType.GRID;
}

// North America (Hollywood) — a "Star": the enemy is invulnerable and immune to
// new debuffs while it shines, but dies when the star fades. The invulnerable
// enemy keeps marching, so starring one near the exit risks a leak.
// Behaviour is enforced in EnemyComponent.receiveDamage + update().
class Star extends Buff {
  Star({required super.caster, required super.level});

  static var durationPerLevel = [2.0, 2.2, 2.4, 2.6, 2.8, 3.0];

  @override
  String name = "Star";

  @override
  String description = "Invulnerable while it shines — then it dies.";

  @override
  IconData icon = FontAwesomeIcons.solidStar.data;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  double? get baseDuration => durationPerLevel.getByLevel(level);

  @override
  RenderType get renderType => RenderType.GRID;
}

// Africa (Nairobi) — Stampede: the charge pierces the whole line (bullet never
// stops) and tramples (slows) everything it passes through.
class StampedeBuff extends Buff {
  StampedeBuff({required super.caster, required super.level});

  static const slowPerLevel = <double>[0.30, 0.35, 0.40, 0.45, 0.50, 0.60];

  @override
  String name = "Stampede";

  @override
  String description = "Trampled by the charging herd.";

  @override
  IconData icon = FontAwesomeIcons.hippo.data;

  @override
  CityType gemType = CityType.AFRICA;

  @override
  double? speedModifier(EnemyComponent enemy) => slowPerLevel.getByLevel(level);

  @override
  bool bulletDidHitEnemy(BulletComponent bullet, EnemyComponent enemy) => false;

  @override
  double? baseDuration = 1.0;

  @override
  RenderType get renderType => RenderType.GRID;
}

// Africa (Kinshasa) — Cobalt: an electrocution aura that damages enemies but
// the jolt SPEEDS THEM UP (negative slow), so place it carefully.
class CobaltBuff extends Buff {
  CobaltBuff({required super.caster, required super.level});

  static const damagePerLevel = <double>[3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
  static const speedupPerLevel = <double>[-0.10, -0.12, -0.14, -0.16, -0.18, -0.20];

  @override
  String name = "Electrocuted";

  @override
  String description = "Electrocuted — taking damage but jolted faster.";

  @override
  IconData icon = FontAwesomeIcons.bolt.data;

  @override
  CityType gemType = CityType.AFRICA;

  @override
  double? get damage => damagePerLevel.getByLevel(level);

  @override
  double? speedModifier(EnemyComponent enemy) =>
      speedupPerLevel.getByLevel(level);

  @override
  double? baseDuration = 0.4;

  @override
  RenderType get renderType => RenderType.GRID;
}
