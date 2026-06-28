import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/hanoi.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/sasia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/samerica.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/mena/mena.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/namerica/namerica.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/africa/africa.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/weurope/weurope.dart';

import '../cities/gems/asean/asean.dart';
import '../cities/gems/eeurope/eeurope.dart';
import '../cities/gems/rock.dart';
import '../cities/gems/special_companies/volgograd.dart';
import '../cities/gems/special_companies/jerusalem.dart';
import '../cities/gems/special_companies/hongkong.dart';
import '../cities/gems/special_companies/paris.dart';
import '../cities/gems/special_companies/washington_dc.dart';
import '../cities/gems/special_companies/sierra_leone.dart';
import '../cities/gems/special_companies/galapagos.dart';
import '../neutral/neutral_settings.dart';

GameConstants gameSettings = GameConstants();

class GameConstants {
  GameConstants._privateConstructor();

  static final GameConstants _instance = GameConstants._privateConstructor();

  factory GameConstants() {
    return _instance;
  }

  NeutralSettings neutral = NeutralSettings();

  Vector2 mapGrid = Vector2(10, 10);
  Vector2? mapPosition;
  late Vector2 mapSize;
  late Vector2 viewPosition;
  late Vector2 viewSize;
  late Vector2 barPosition;
  late Vector2 barSize;
  late Vector2 mapTileSize;

  double cannonBulletSpeed = 400;
  double cannonBulletDamage = 10;

  Vector2 enemySizeCale = Vector2(0.9, 0.9);
  late Vector2 enemySize;
  late Vector2 enemySpawn;
  late Vector2 enemyTarget;
  double enemySpeed = 80;

  late Vector2 screenSize;

  Vector2 dotMultiple(Vector2 x, Vector2 y) {
    return Vector2(x.x * y.x, x.y * y.y);
  }

  Vector2 dotDivide(Vector2 x, Vector2 y) {
    return Vector2(x.x / y.x, x.y / y.y);
  }

  Vector2 scaleOnMapTile(Vector2 scale) {
    return dotMultiple(mapTileSize, scale);
  }

  void setScreenSize(Vector2 size) {
    screenSize = size;
    optimizeMapGrid(size);

    enemySize = dotMultiple(enemySizeCale, mapTileSize);
    enemySpawn = Vector2(0, 0) + (mapTileSize / 2);
    enemyTarget = (mapSize) - (mapTileSize / 2);

    print(
        'screenSize $screenSize,  mapGrid $mapGrid, mapTileSize $mapTileSize');
  }

  void optimizeMapGrid(Vector2 size) {
    mapGrid = Vector2(10, 10);
    double grid = math.min(mapGrid.x, mapGrid.y);
    Vector2 optSize = size / grid;
    grid = math.min(optSize.x, optSize.y);

    /*Bar at top*/
    barPosition = Vector2(size.x / 2, size.y - grid / 2);
    barSize = Vector2(size.x, grid * 5);
    viewPosition = Vector2(size.x / 2, size.y - (grid / 2));
    viewSize = Vector2(size.x, grid * 1.5);
    mapSize = Vector2(size.x - 2, size.y - barSize.y - viewSize.y - 2);
    mapGrid = Vector2(8, 11);
    mapTileSize =
        dotDivide(Vector2(mapSize.x, mapSize.x), Vector2(mapGrid.x, mapGrid.x));
    // need to recalculate since we determine size based on grid and tile size
    mapSize = Vector2(mapGrid.x * mapTileSize.x, mapGrid.y * mapTileSize.y);
    /*This is the center position of map*/
    mapPosition = mapPosition ?? Vector2(size.x / 2, 0 + mapSize.y / 2);
    print("mapsize:$mapSize");
    print("grid:$grid");
    mapGrid = Vector2(8, 11);
    mapTileSize =
        dotDivide(Vector2(mapSize.x, mapSize.x), Vector2(mapGrid.x, mapGrid.x));
  }

  /*
   *
   * GEM HELPERS
   * TODO: Refactor!
   * 
   */
  static List<GemComponent> gems = [
    EAsia(),
    EEurope(),
    Asean(),
    SAmerica(),
    Mena(),
    Africa(),
    WEurope(),
    NAmerica(),
  ];
  // helper for selecting a gem with no level at random
  static GemComponent randomGem() {
    var nextInt = math.Random().nextInt(gems.length);
    return gems[nextInt].equivalentGem();
  }

  static GemComponent gemByType(CityType type) {
    switch (type) {
      case CityType.EASIA:
        return EAsia();
      case CityType.EEUROPE:
        return EEurope();
      case CityType.ASEAN:
        return Asean();
      case CityType.SAMERICA:
        return SAmerica();
      case CityType.MENA:
        return Mena();
      case CityType.SASIA:
        return SAsia();
      case CityType.WEUROPE:
        return WEurope();
      case CityType.NAMERICA:
        return NAmerica();
      case CityType.AFRICA:
        return Africa();
      default:
        return Rock();
    }
  }

  static List<Map<int, double>> odds = [
    {
      1: 1.0,
    },
    {
      1: 0.9,
      2: 0.1,
    },
    {
      1: 0.8,
      2: 0.2,
    },
    {
      1: 0.7,
      2: 0.3,
    },
    {
      1: 0.6,
      2: 0.4,
    },
    {
      1: 0.5,
      2: 0.4,
      3: 0.1,
    },
    {
      1: 0.4,
      2: 0.4,
      3: 0.2,
    },
    {
      1: 0.3,
      2: 0.5,
      3: 0.2,
    },
    {
      1: 0.2,
      2: 0.6,
      3: 0.2,
    },
    {
      2: 0.5,
      3: 0.4,
      4: 0.1,
    },
    {
      2: 0.4,
      3: 0.4,
      4: 0.2,
    },
    {
      2: 0.3,
      3: 0.5,
      4: 0.2,
    },
    {
      2: 0.2,
      3: 0.6,
      4: 0.2,
    },
    {
      3: 0.5,
      4: 0.4,
      5: 0.1,
    },
    {
      3: 0.4,
      4: 0.4,
      5: 0.2,
    },
    {
      3: 0.3,
      4: 0.5,
      5: 0.2,
    },
    {
      3: 0.2,
      4: 0.6,
      5: 0.2,
    },
    {
      3: 0.2,
      4: 0.4,
      5: 0.4,
    },
  ];

  static int caclculateLevel(int level, double nextDouble) {
    for (var entry in odds.getByLevel(level).entries) {
      if (nextDouble < entry.value) {
        return entry.key;
      } else {
        nextDouble -= entry.value;
      }
    }
    return 1;
  }

  static Map<List<String>, GemComponent> basicRecipes = {
    [(Asean()..level = 1).name, (Asean()..level = 1).name]: Asean()..level = 2,
    [(Asean()..level = 2).name, (Asean()..level = 2).name]: Asean()..level = 3,
    [(Asean()..level = 3).name, (Asean()..level = 3).name]: Asean()..level = 4,
    [(Asean()..level = 4).name, (Asean()..level = 4).name]: Asean()..level = 5,
    //TODO(alex, agree) for EAsia we have 5 + 5 -> 6, but for Asean don't, maybe forgot?
    [(Asean()..level = 5).name, (Asean()..level = 5).name]: Asean()..level = 6,
    [(EAsia()..level = 1).name, (EAsia()..level = 1).name]: EAsia()..level = 2,
    [(EAsia()..level = 2).name, (EAsia()..level = 2).name]: EAsia()..level = 3,
    [(EAsia()..level = 3).name, (EAsia()..level = 3).name]: EAsia()..level = 4,
    [(EAsia()..level = 4).name, (EAsia()..level = 4).name]: EAsia()..level = 5,
    [(EAsia()..level = 5).name, (EAsia()..level = 5).name]: EAsia()..level = 6,
    [(SAmerica()..level = 1).name, (SAmerica()..level = 1).name]: SAmerica()
      ..level = 2,
    [(SAmerica()..level = 2).name, (SAmerica()..level = 2).name]: SAmerica()
      ..level = 3,
    [(SAmerica()..level = 3).name, (SAmerica()..level = 3).name]: SAmerica()
      ..level = 4,
    [(SAmerica()..level = 4).name, (SAmerica()..level = 4).name]: SAmerica()
      ..level = 5,
    [(Mena()..level = 1).name, (Mena()..level = 1).name]: Mena()
      ..level = 2,
    [(Mena()..level = 2).name, (Mena()..level = 2).name]: Mena()
      ..level = 3,
    [(Mena()..level = 3).name, (Mena()..level = 3).name]: Mena()
      ..level = 4,
    [(Mena()..level = 4).name, (Mena()..level = 4).name]: Mena()
      ..level = 5,
    [(SAsia()..level = 1).name, (SAsia()..level = 1).name]: SAsia()
      ..level = 2,
    [(SAsia()..level = 2).name, (SAsia()..level = 2).name]: SAsia()
      ..level = 3,
    [(SAsia()..level = 3).name, (SAsia()..level = 3).name]: SAsia()
      ..level = 4,
    [(SAsia()..level = 4).name, (SAsia()..level = 4).name]: SAsia()
      ..level = 5,
    [(EEurope()..level = 1).name, (EEurope()..level = 1).name]: EEurope()
      ..level = 2,
    [(EEurope()..level = 2).name, (EEurope()..level = 2).name]: EEurope()
      ..level = 3,
    [(EEurope()..level = 3).name, (EEurope()..level = 3).name]: EEurope()
      ..level = 4,
    [(EEurope()..level = 4).name, (EEurope()..level = 4).name]: EEurope()
      ..level = 5,
    [(EEurope()..level = 5).name, (EEurope()..level = 5).name]: EEurope()
      ..level = 6,
    [(WEurope()..level = 1).name, (WEurope()..level = 1).name]: WEurope()
      ..level = 2,
    [(WEurope()..level = 2).name, (WEurope()..level = 2).name]: WEurope()
      ..level = 3,
    [(WEurope()..level = 3).name, (WEurope()..level = 3).name]: WEurope()
      ..level = 4,
    [(WEurope()..level = 4).name, (WEurope()..level = 4).name]: WEurope()
      ..level = 5,
    [(WEurope()..level = 5).name, (WEurope()..level = 5).name]: WEurope()
      ..level = 6,
    [(NAmerica()..level = 1).name, (NAmerica()..level = 1).name]: NAmerica()
      ..level = 2,
    [(NAmerica()..level = 2).name, (NAmerica()..level = 2).name]: NAmerica()
      ..level = 3,
    [(NAmerica()..level = 3).name, (NAmerica()..level = 3).name]: NAmerica()
      ..level = 4,
    [(NAmerica()..level = 4).name, (NAmerica()..level = 4).name]: NAmerica()
      ..level = 5,
    [(NAmerica()..level = 5).name, (NAmerica()..level = 5).name]: NAmerica()
      ..level = 6,
    [(Africa()..level = 1).name, (Africa()..level = 1).name]: Africa()..level = 2,
    [(Africa()..level = 2).name, (Africa()..level = 2).name]: Africa()..level = 3,
    [(Africa()..level = 3).name, (Africa()..level = 3).name]: Africa()..level = 4,
    [(Africa()..level = 4).name, (Africa()..level = 4).name]: Africa()..level = 5,
    [(Africa()..level = 5).name, (Africa()..level = 5).name]: Africa()..level = 6,
  };

  static Map<List<String>, GemComponent> specialRecipes = {
    hanoi_recipe.cities: hanoi_recipe.gem,
    volgograd_recipe.cities: volgograd_recipe.gem,
    jerusalem_recipe.cities: jerusalem_recipe.gem,
    hongkong_recipe.cities: hongkong_recipe.gem,
    paris_recipe.cities: paris_recipe.gem,
    washington_dc_recipe.cities: washington_dc_recipe.gem,
    sierra_leone_recipe.cities: sierra_leone_recipe.gem,
    galapagos_recipe.cities: galapagos_recipe.gem,
    // [
    //   (Finance()..level = 1).name, // robinhood
    //   (Mena()..level = 2).name, // reddit
    //   (Tech()..level = 1).name, // ibm
    // ]: Coinbase(),
    // [
    //   (Asean()..level = 1).name, // CBS
    //   (SAsia()..level = 2).name, // Budweiser
    //   (EAsia()..level = 5).name, // Las Vegas Sands
    // ]: NFL(),
    // [
    //   (Auto()..level = 2).name, // ford
    //   (Auto()..level = 1).name, // subaru
    //   (SAmerica()..level = 1).name, // h & m
    // ]: Jeep(),
    // [
    //   (Mena()..level = 3).name, // facebook
    //   (Tech()..level = 4).name, // meta
    //   (Mena()..level = 5).name, // insta
    // ]: WhatsApp(),
    // [
    //   (Auto()..level = 5).name, // tesla
    //   (Mena()..level = 4).name, // twitter
    //   (Finance()..level = 2).name, // venmo
    // ]: Defense()..level = 5,
    // [
    //   (SAsia()..level = 4).name, // starbucks
    //   (Tech()..level = 3).name, // amazon
    //   (Tech()..level = 2).name, // microsoft
    // ]: Defense()..level = 4,
    // [
    //   // Red Bull
    //   (SAmerica()..level = 3).name, // ADIDAS
    //   (Auto()..level = 3).name, // BMW
    //   (SAsia()..level = 3).name, // microsoft
    // ]: FIFA(),
    // [
    //   (Mena()..level = 1).name, // snapchat
    //   (EAsia()..level = 1).name, //holiday inn
    //   (Asean()..level = 5).name, //netflix
    // ]: Tinder(),
    // [
    //   //McDonals
    //   (SAsia()..level = 1).name,
    //   (EAsia()..level = 2).name, //MGM
    //   (SAmerica()..level = 4).name, //Nike
    // ]: NBA(),
    // [
    //   (Asean()..level = 1).name, // Fox
    //   (SAsia()..level = 5).name, // Chick Fil A
    //   (Finance()..level = 3).name, // Bank of America
    // ]: FoxNews(),
    // [
    //   (SAmerica()..level = 5).name, // hermes
    //   (Finance()..level = 5).name, // gs
    //   (Auto()..level = 4).name,
    //   // proche
    // ]: BlackRock(),

    // 1, 1, 1
    // 1, 1, 1
    // 1, 1, 2

    // 2, 3, 4
    // 2, 3, 5
    // 2, 3, 5
    // 2, 4, 4
    // 2, 4, 4

    // 3, 4, 5
    // 3, 4, 5
    // 4, 4, 5

    // 3, 3, 5
    // 2, 2, 3, 5
  };

  // // TODO: SUPER SLOW, CAN REFACTOR TO BE MUCH FASTER!
  static Map<List<GemComponent>, GemComponent> combinations(
    GemComponent gem,
    List<GemComponent> otherGems,
    Map<List<String>, GemComponent> recipes,
  ) {
    //
    Map<List<GemComponent>, GemComponent> result = {};
    //
    List<GemComponent> _otherGems = List.from(otherGems)..remove(gem);

    for (List<String> ingredients in recipes.keys) {
      List<GemComponent> list = [];

      if (ingredients.contains(gem.name)) {
        var _remainder = List.from(ingredients);
        _remainder.remove(gem.name);
        list.add(gem);

        for (GemComponent otherGem in _otherGems) {
          if (_remainder.contains(otherGem.name)) {
            _remainder.remove(otherGem.name);
            list.add(otherGem);
            if (_remainder.isEmpty) {
              // TODO: This is only done because of pass by reference issues
              result[list] = recipes[ingredients]!.equivalentGem();

              // result[list] = recipes[ingredients]!;
              break;
            }
          }
        }
      }
    }

    return result;
  }

  // class needs a refactor
  // should ideally return gemcomponent list for easier render but sending string
  // because lazy. TODO: Consider how to improve this
  static Map<List<String>, GemComponent> getRecipe(
    GemComponent gem,
    Map<List<String>, GemComponent> recipes,
  ) {
    Map<List<String>, GemComponent> result = {};

    for (List<String> ingredients in recipes.keys) {
      if (ingredients.contains(gem.name)) {
        result = {ingredients: recipes[ingredients]!};
        break;
      }
    }

    return result;
  }
}
