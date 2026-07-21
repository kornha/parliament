import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart' as ab;
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/status_manager.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/life_indicator.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/radar.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/scanable.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/aura_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/rock.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/foxnews.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/nba.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/nfl.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/tinder.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/croatia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/belgium.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/north_korea.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/qatar.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/el_salvador.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/singapore.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/sierra_leone.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/galapagos.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/macau.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/turkey.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/monaco.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/greenland.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/myanmar.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/romania.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/uruguay.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/madagascar.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';

import 'gems/special_companies/blackrock.dart';
import 'gems/special_companies/coinbase.dart';
import 'gems/special_companies/fifa.dart';
import 'gems/special_companies/hard_rock.dart';

enum CityType {
  EASIA,
  EEUROPE,
  MENA,
  SASIA,
  ASEAN,
  SAMERICA,
  NAMERICA,
  WEUROPE,
  AFRICA,
  ROCK;

  // South Asia (SASIA) is deferred — replaced by Africa as the 8th live region.
  static List<CityType> activeValues = [
    EASIA,
    EEUROPE,
    MENA,
    ASEAN,
    SAMERICA,
    NAMERICA,
    WEUROPE,
    AFRICA,
  ];

  Color color() {
    switch (this) {
      case CityType.EASIA:
        return Palette.eAsiaRed;
      case CityType.EEUROPE:
        return Colors.yellow;
      case CityType.MENA:
        return Palette.menaGreen;
      case CityType.SASIA:
        return Colors.green;
      case CityType.ASEAN:
        return Palette.aseanBlue;
      case CityType.SAMERICA:
        return Colors.red;
      case CityType.NAMERICA:
        return Palette.nAmericaNavy;
      case CityType.WEUROPE:
        return Colors.cyan;
      case CityType.AFRICA:
        return Colors.orange;
      case CityType.ROCK:
        return Colors.black;
    }
  }

  Color secondaryColor() {
    switch (this) {
      case CityType.NAMERICA:
        return Palette.nAmericaRed;
      case CityType.SASIA:
        return Colors.black;
      case CityType.WEUROPE:
        return Colors.black;
      case CityType.MENA:
        return Colors.white;
      case CityType.EEUROPE:
        return Colors.black;
      case CityType.ASEAN:
        return Palette.aseanRed;
      case CityType.AFRICA:
        return Colors.brown;

      default:
        return Colors.white;
    }
  }
}

// Each country's signature flag color, used to tint its attacks/explosions and
// aura ring. Keyed by lowercase ISO code (matches the flag asset codes).
const Map<String, int> flagColors = {
  // Eastern Europe
  'lv': 0xFF9E1B32, 'hu': 0xFFCD2A3E, 'cz': 0xFF11457E,
  'ua': 0xFF0057B7, 'pl': 0xFFDC143C, 'ru': 0xFFD52B1E,
  // Western Europe
  'ie': 0xFF169B62, 'es': 0xFFAA151B, 'it': 0xFF008C45,
  'pt': 0xFF006600, 'fr': 0xFF0055A4, 'gb': 0xFF012169,
  // East Asia
  'mn': 0xFFC4272E, 'tw': 0xFFFE0000, 'hk': 0xFFDE2910,
  'kr': 0xFFCD2E3A, 'jp': 0xFFBC002D, 'cn': 0xFFDE2910,
  // MENA
  'lb': 0xFFED1C24, 'ma': 0xFFC1272D, 'eg': 0xFFCE1126,
  'sa': 0xFF006C35, 'ae': 0xFF00732F, 'il': 0xFF0038B8,
  // North America
  'cu': 0xFF002A8F, 'jm': 0xFF009B3A, 'pa': 0xFF005293,
  'ca': 0xFFFF0000, 'mx': 0xFF006847, 'us': 0xFF0A3161,
  // South America
  'pe': 0xFFD91023, 'cl': 0xFFD52B1E, 'co': 0xFFFCD116,
  've': 0xFFFFCC00, 'ar': 0xFF74ACDF, 'br': 0xFF009C3B,
  // ASEAN
  'kh': 0xFF032EA1, 'vn': 0xFFDA251D, 'ph': 0xFF0038A8,
  'id': 0xFFFF0000, 'my': 0xFF010066, 'th': 0xFF241D4F,
  // Africa
  'gh': 0xFFFCD116, 'et': 0xFF078930, 'cd': 0xFF007FFF,
  'ke': 0xFF006600, 'ng': 0xFF008751, 'za': 0xFF007A4D,
  // Specials
  'hr': 0xFFFF0000, 'be': 0xFFFDDA24, 'kp': 0xFFED1C27,
  'qa': 0xFF8A1538, 'sv': 0xFF0F47AF, 'ec': 0xFFFFDD00,
  'sg': 0xFFEF3340, 'sl': 0xFF1EB53A,
  'mo': 0xFF00785E, 'tr': 0xFFE30A17, 'mc': 0xFFCE1126,
  'gl': 0xFFD00C33, 'mm': 0xFF34B233, 'ro': 0xFF002B7F,
  'uy': 0xFF0038A8, 'mg': 0xFF007E3A,
};

abstract class GemComponent extends GameComponent
    with TapCallbacks, Radar<GameComponent>, LifeIndicator, Scanable {
  // attribute stats
  GemAttributes get settings;

  late CityType gemType = settings.gemType;

  //late BarrelComponent barrelComponent;
  //late List<Sprite?> barrels = List.filled(3, null);

  late double currentDamage;
  late double currentBulletSpeed;
  late double currentRange;
  late double currentAttackSpeed;
  late double currentBountyMultiplier = 1.0;

  // currently only effects enemy buff durations since its implemented
  // on fire
  late double currentBuffMultiplier = 1.0;

  @override
  double get radarRange => !buildDone
      ? (size.x + size.y) / 4
      : currentRange * gameSettings.mapTileSize.length;

  double get currentFireInterval => 1.0 / currentAttackSpeed;

  GemComponent({
    Vector2? position,
    double life = 100,
    this.hideSprite = false,
    this.autobuild = false,
    int priority = Constants.CITY_PRIORITY,
  }) : super(position: position, priority: priority);

  // what is this used for..?
  @override
  bool active = true;

  Set<bf.Buff> buffs = {};
  late Set<ab.Ability> abilities = settings.abilities(level, this);

  // Buffs that come and go on a fast cycle (per-attack compounders, aura pulses)
  // are re-applied moments after they expire — technically absent for a frame or
  // two, which made their icons blink. For display purposes a buff keeps showing
  // until it has been absent this long.
  static const _buffLingerSecs = 1.0;
  final Map<bf.Buff, double> _buffLastSeen = {};

  // The stable, non-blinking view of this tower's buffs (for icons/panels).
  Set<bf.Buff> get displayBuffs => _buffLastSeen.keys.toSet();

  EnemyComponent? lastEnemy;
  int fireCount = 0;

  // controls TODO need refactor
  bool blockMap = false;
  bool blockEnemy = true;
  bool buildDone = false;
  bool dialogVisible = false;
  bool hideSprite;
  bool autobuild;

  // stats
  int level = 1;
  double bounty = 0;

  // late image inits
  late SpriteSheet projectileSheet;
  late SpriteSheet auraSheet;

  // function vars
  get buildAllowed => !blockMap && !blockEnemy;

  get currentImagePath => "innovation/${name.toLowerCase()}.png";

  get wasPlacedThisRound =>
      gameRef.placeController.gemsThisRound?.contains(this) ?? false;

  get name => settings.name(level);

  // A country's attacks + explosions are tinted to its flag's signature color
  // (falls back to the region color for rocks / unmapped codes).
  Color get color {
    final code =
        countryCodes.isNotEmpty ? countryCodes.first.toLowerCase() : null;
    final hex = code == null ? null : flagColors[code];
    return hex != null ? Color(hex) : gemType.color();
  }

  List<String> get countryCodes => settings.countryCodes(level);

  @override
  Future<void>? onLoad() async {
    size = settings.size;
    currentAttackSpeed = settings.baseAttackSpeed(level);
    currentDamage = settings.baseDamage(level);
    currentBulletSpeed = settings.projectileSpeed;
    currentRange = settings.baseRange(level);
    //
    if (hideSprite) {
      Sprite.load(currentImagePath);
    } else {
      sprite = await Sprite.load(currentImagePath);
    }
    //
    if (settings.isAura(level)) {
      auraSheet = await SpriteSheet.fromColumnsAndRows(
        image: await Images().load(settings.auraPath),
        columns: settings.auraColumns(level),
        rows: settings.auraRows(level),
      );
    } else {
      projectileSheet = await SpriteSheet.fromColumnsAndRows(
        image: await Images().load(settings.projectilePath),
        columns: settings.projectileColumns(level),
        rows: settings.projectileRows(level),
      );
    }

    //
    if (autobuild) {
      onBuildDone();
    } else {
      onBuilding();
    }

    return super.onLoad();
  }

  @override
  double _auraPhase = 0;
  double _timeSinceEnemy = 999;

  @override
  void update(double dt) {
    super.update(dt);

    StatusManager.tickGem(dt, this, buffs);

    // Age the display linger and refresh it with the currently active buffs.
    // Remove-then-add so the map holds the LIVE instance (a re-applied buff is
    // == its predecessor but may carry new state, e.g. a fresh crit multiplier).
    _buffLastSeen.updateAll((b, t) => t + dt);
    _buffLastSeen.removeWhere((b, t) => t > _buffLingerSecs);
    for (final b in buffs) {
      _buffLastSeen.remove(b);
      _buffLastSeen[b] = 0;
    }

    _timeSinceEnemy += dt;
    if (settings.auraRing(level)) {
      _auraPhase = (_auraPhase + dt / 1.6) % 1.0;
    }
  }

  @override
  void render(Canvas canvas) {
    // Aura towers emit a soft, flag-colored ripple out to their range — but
    // only while an enemy is nearby (radiate on demand, not constantly). Each
    // ring undulates like rippling fabric, and the waves travel as it spreads.
    if (buildDone && settings.auraRing(level) && _timeSinceEnemy < 1.2) {
      final center = (size / 2).toOffset();
      // Fade out over ~1.2s once enemies leave range (also covers slow-firing
      // aura towers whose radar cycles off between pulses).
      final presence = (1.0 - _timeSinceEnemy / 1.2).clamp(0.0, 1.0);
      final maxR = radarRange;
      const waves = 7;
      const steps = 56;
      for (final off in const [0.0, 0.33, 0.66]) {
        final p = (_auraPhase + off) % 1.0;
        final r = maxR * p;
        if (r <= 1.0) continue;
        // Wobble amplitude grows as the ripple loosens outward (fabric slack).
        final amp = maxR * 0.06 * p;
        final phase = _auraPhase * 2 * pi + off * 2 * pi;
        final path = Path();
        for (int i = 0; i <= steps; i++) {
          final a = (i / steps) * 2 * pi;
          final rr = r + amp * sin(waves * a + phase);
          final px = center.dx + cos(a) * rr;
          final py = center.dy + sin(a) * rr;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
            ..color = color.withOpacity(
                (0.55 * presence * (1.0 - 0.5 * p)).clamp(0.0, 1.0)),
        );
      }
    }

    super.render(canvas);

    if (!buildDone || dialogVisible == true) {
      Color? color = buildAllowed ? Colors.green[200] : Colors.red[200];
      // cosmetic
      Rect r = Rect.fromLTWH(
          size.x * 0.05, size.y * 0.05, size.x * 0.9, size.y * 0.9);

      canvas.drawRect(r, Paint()..color = color!.withOpacity(0.3));

      if (dialogVisible == true) {
        Color? color = Colors.blue[200];
        /*build indicator */
        canvas.drawRect(
            size.toRect(), Paint()..color = color!.withOpacity(0.3));
        canvas.drawCircle(
            (size / 2).toOffset(),
            radarRange,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.white);
      }
    }

    renderBuffs(canvas, displayBuffs);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    gameRef.weaponFactory.onGemSelected(this);
    return false;
  }

  void fire(EnemyComponent? target) {
    _targetEnemy = target;
    // double radians = angleNearTo(target);
    // double rotatePeriod = barrelComponent.rotateTo(radians, _fireByType);
    _fireByType();
    coolDown(currentFireInterval);
  }

  EnemyComponent? _targetEnemy;

  void _fireByType() {
    if (_targetEnemy != null) {
      if (settings.isAura(level)) {
        fireAura();
      } else {
        fireBullet(_targetEnemy!);
      }
    }
    _targetEnemy = null;
    fireCount++;
  }

  void fireAura() {
    var tempDamage = currentDamage;
    // // //
    //
    Set<Buff> bbuffs = Buff.getFiringBuffs(abilities, this);
    //
    //
    AuraComponent ac = AuraComponent(
      position: position,
      spriteSheet: auraSheet,
      projectileStepTime: settings.auraStepTime,
      projectileScale: settings.auraScale,
      scanSize: radarRange,
      source: this,
    )
      ..damage = tempDamage
      ..buffs = bbuffs;
    parent?.add(ac);

    // reset damage
    // currentDamage = settings.baseDamage(level);
  }

  void fireBullet(EnemyComponent enemy) {
    var tempDamage = currentDamage;
    // // //
    double rad = angleNearTo(enemy.position);
    //
    Set<Buff> bbuffs = Buff.getFiringBuffs(abilities, this);
    //
    BulletComponent bc = BulletComponent(
      position: _bulletPosition(rad),
      size: settings.bulletSize,
      enemy: enemy,
      spriteSheet: projectileSheet,
      loop: settings.projectLoop,
      projectileStepTime: settings.projectileStepTime,
      settings: settings,
      source: this,
    )
      ..canHitIntermediateTargets = settings.canHitIntermediateTargets
      ..damage = tempDamage
      ..speed = currentBulletSpeed
      ..buffs = bbuffs;
    parent?.add(bc);

    // reset damage
    // currentDamage = settings.baseDamage(level);
  }

  Vector2 _bulletPosition(angle) {
    // double bulletR = (setting.bulletSize.x + setting.bulletSize.y) / 4;
    double r = radius /*+ bulletR*/;
    Vector2 localPosition = Vector2(
      r * sin(angle),
      -r * cos(angle),
    );
    localPosition += (size / 2);
    return positionOf(localPosition);
  }

  void coolDown(double period) {
    radarOn = false;
    add(
      TimerComponent(
        period: period,
        repeat: false,
        removeOnFinish: true,
        onTick: () {
          // tick attack here after cooldown since otherwise
          // buffs will vanish immediately after attack
          StatusManager.tickAttack(buffs);
          radarOn = true;
        },
      ),
    );
  }

  void onBuilding() {
    scanable = false;
    buildDone = false;
    radarOn = true;
    radarScanAlert = onEnemyBlock;
    radarScanNothing = onEnemyUnBlock;
    radarCollisionDepth = 0;
  }

  void onBuildDone() {
    scanable = true;
    buildDone = true;
    dialogVisible = false;
    radarOn = true;
    radarScanAlert = onEnemyAttack;
    radarScanNothing = null;
    radarCollisionDepth = 0;
    radarScanAllies = onGemScan;
    abilities.forEach((element) {
      element.onGemBuilt(this);
    });
  }

  Future unhide() async {
    hideSprite = false;
    sprite = await Sprite.load(currentImagePath);
  }

  void convertTo(GemComponent other) {
    // need to turn off so there's no scans during conversion
    radarOn = false;

    // set captures from primary conversion gem
    // this does not set captures in case of special combinations secondary towers
    // we do that right before downgrade
    other
      ..position = position
      ..bounty = bounty
      ..autobuild = true;
    removeFromParent();
    parent?.add(other);

    gameRef.gameController.queue(this, GameControl.GEM_CONVERTED, other);
  }

  // void upgrade() {
  //   convertTo(equivalentGem()..level = level + 1);
  // }

  void downGrade() {
    convertTo(Rock());
  }

  void onEnemyBlock(GameComponent target, Set<GameComponent> targets) {
    blockEnemy = true;
  }

  void onEnemyUnBlock() {
    blockEnemy = false;
  }

  void onEnemyAttack(GameComponent target, Set<GameComponent> targets) {
    _timeSinceEnemy = 0;
    bool shouldAttack = true;
    GameComponent? targetEnemy = target;
    abilities.forEach((ability) {
      //scan call for each enemy, even those not attacked
      var e = ability.onEnemyAttack(this, target as EnemyComponent, targets);
      // we override on who to attack here
      // todo -- can make this a list!
      if (e != null && e != target) {
        targetEnemy = e;
      }
      if (ability.canAttack == false) {
        shouldAttack = false;
      }
    });

    StatusManager.computeGemStatus(buffs, this);

    if (shouldAttack) {
      var enemy = targetEnemy as EnemyComponent;
      fire(enemy);
    }

    lastEnemy = targetEnemy as EnemyComponent;
  }

  void onGemScan(Set<GemComponent> allies) {
    abilities.forEach((element) {
      element.onAuraScan(allies);
    });
  }

  bool canDestroy() {
    return settings.gemType == CityType.ROCK;
  }

  void destroy() {
    active = false;
    removeFromParent();
    gameRef.gameController.queue(this, GameControl.WEAPON_DESTROYED);
  }

  //TODO: this is a lazy approach
  bool isEquivalentValue(GemComponent other) {
    return settings.gemType == other.settings.gemType && level == other.level;
  }

  onEnemyKilled(EnemyComponent enemy) {
    bounty += enemy.settings.baseCapital(enemy.level) * currentBountyMultiplier;
  }

  GemComponent equivalentGem() {
    // TODO: HACK! This should be a factory
    // TODO: bump
    //TODO(alex: confirm) do we need these all old gems?
    if (name == "HardRock") return HardRock();
    if (name == "Coinbase") return Coinbase();
    if (name == "FIFA") return FIFA();
    if (name == "NBA") return NBA();
    if (name == "Fox News") return FoxNews();
    if (name == "BlackRock") return BlackRock();
    if (name == "Tinder") return Tinder();
    if (name == "NFL") return NFL();

    // Special cities (cross-region recipes)
    if (name == "Croatia") return Croatia();
    if (name == "Belgium") return Belgium();
    if (name == "North Korea") return NorthKorea();
    if (name == "Qatar") return Qatar();
    if (name == "El Salvador") return ElSalvador();
    if (name == "Singapore") return Singapore();
    if (name == "Sierra Leone") return SierraLeone();
    if (name == "Galapagos") return Galapagos();
    if (name == "Macau") return Macau();
    if (name == "Turkey") return Turkey();
    if (name == "Monaco") return Monaco();
    if (name == "Greenland") return Greenland();
    if (name == "Myanmar") return Myanmar();
    if (name == "Romania") return Romania();
    if (name == "Uruguay") return Uruguay();
    if (name == "Madagascar") return Madagascar();

    return GameConstants.gemByType(gemType)..level = level;
  }
}
