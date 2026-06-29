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

  get color => gemType.color();

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
  void update(double dt) {
    super.update(dt);

    StatusManager.tickGem(dt, this, buffs);
  }

  @override
  void render(Canvas canvas) {
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

    renderBuffs(canvas, buffs);
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

    return GameConstants.gemByType(gemType)..level = level;
  }
}
