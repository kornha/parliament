import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/status_manager.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  gameSettings.setScreenSize(Vector2(400, 800));

  test('two of the same special: aura + enemy buff pipeline', () {
    for (final proto in GameConstants.specialRecipes.values.toList()) {
      final label = proto.name;
      GemComponent a;
      GemComponent b;
      Set<Ability> abA;
      Set<Ability> abB;
      try {
        a = proto.equivalentGem()..position = Vector2(0, 0);
        b = proto.equivalentGem()..position = Vector2(10, 0);
        a.currentDamage = 10;
        b.currentDamage = 10;
        a.currentRange = 3;
        b.currentRange = 3;
        a.currentAttackSpeed = 1;
        b.currentAttackSpeed = 1;
        abA = a.abilities;
        abB = b.abilities;
      } catch (e) {
        // ignore: avoid_print
        print('ERR(build) $label -> $e');
        continue;
      }

      final enemy =
          EnemyComponent(position: Vector2(1, 0), size: Vector2(10, 10));
      enemy.maxLife = 1000;
      enemy.life = 1000;
      enemy.level = 3;

      try {
        for (var frame = 0; frame < 30; frame++) {
          for (final ab in abA) {
            ab.onAuraScan({a, b});
          }
          for (final ab in abB) {
            ab.onAuraScan({a, b});
          }
          StatusManager.tickGem(0.05, a, a.buffs);
          StatusManager.tickGem(0.05, b, b.buffs);

          final fa = Buff.getFiringBuffs(abA, a);
          final fb = Buff.getFiringBuffs(abB, b);
          enemy.receiveDamage(1, fa, a);
          enemy.receiveDamage(1, fb, b);
          StatusManager.tickEnemy(0.05, enemy, enemy.buffs);
        }
        // ignore: avoid_print
        print('OK  $label gemBuffs=${a.buffs.length} enemyBuffs=${enemy.buffs.length}');
      } catch (e, st) {
        // ignore: avoid_print
        print('ERR(run) $label -> ${e.runtimeType}: $e\n'
            '${st.toString().split("\n").take(10).join("\n")}');
      }
    }
  });

  test('one special only: same pipeline (control)', () {
    for (final proto in GameConstants.specialRecipes.values.toList()) {
      final label = proto.name;
      GemComponent a;
      Set<Ability> abA;
      try {
        a = proto.equivalentGem()..position = Vector2(0, 0);
        a.currentDamage = 10;
        a.currentRange = 3;
        a.currentAttackSpeed = 1;
        abA = a.abilities;
      } catch (e) {
        // ignore: avoid_print
        print('ERR(build) $label -> $e');
        continue;
      }
      final enemy =
          EnemyComponent(position: Vector2(1, 0), size: Vector2(10, 10));
      enemy.maxLife = 1000;
      enemy.life = 1000;
      enemy.level = 3;
      try {
        for (var frame = 0; frame < 30; frame++) {
          for (final ab in abA) {
            ab.onAuraScan({a});
          }
          StatusManager.tickGem(0.05, a, a.buffs);
          final fa = Buff.getFiringBuffs(abA, a);
          enemy.receiveDamage(1, fa, a);
          StatusManager.tickEnemy(0.05, enemy, enemy.buffs);
        }
        // ignore: avoid_print
        print('OK  $label gemBuffs=${a.buffs.length} enemyBuffs=${enemy.buffs.length}');
      } catch (e, st) {
        // ignore: avoid_print
        print('ERR(run) $label -> ${e.runtimeType}: $e\n'
            '${st.toString().split("\n").take(10).join("\n")}');
      }
    }
  });
}
