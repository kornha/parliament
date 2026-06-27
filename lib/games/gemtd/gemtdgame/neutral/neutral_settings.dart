import 'package:flame/cache.dart';
import 'package:flame/components.dart';

class NeutralSettings {
  late Sprite mine;
  late Sprite mineCluster;

  Future<void> load() async {
    final images = Images();
    //mine = Sprite(await images.load('neutual/mine.png'));
    //mineCluster = Sprite(await images.load('neutual/mine_cluster.png'));
  }
}
