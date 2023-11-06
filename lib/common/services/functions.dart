import 'package:cloud_functions/cloud_functions.dart';
import 'package:political_think/common/models/position.dart';

class Functions {
  Functions.instance();

  Future<void> joinRoom(String pid, {Quadrant? position}) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('joinRoom');

    try {
      final HttpsCallableResult result = await callable.call({
        'pid': pid,
        'position': position?.name,
      });
    } catch (e) {
      print(e);
    }
  }
}
