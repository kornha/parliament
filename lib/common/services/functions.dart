import 'package:cloud_functions/cloud_functions.dart';
import 'package:political_think/common/models/platform.dart';

class Functions {
  Functions.instance();

  // Future<void> joinRoom(String pid, {Quadrant? position}) async {
  //   final HttpsCallable callable =
  //       FirebaseFunctions.instance.httpsCallable('joinRoom');

  //   try {
  //     final HttpsCallableResult result = await callable.call({
  //       'pid': pid,
  //       'position': position?.name,
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // Future<HttpsCallableResult> startDebate(String rid,
  //     {Quadrant? position}) async {
  //   final HttpsCallable callable =
  //       FirebaseFunctions.instance.httpsCallable('startDebate');
  //   return await callable.call({
  //     'rid': rid,
  //   });
  // }

  Future<void> triggerContent() async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('onTriggerContent');

    try {
      final HttpsCallableResult result = await callable.call({
        'source': 'perigon',
      });
    } catch (e) {
      print(e);
    }
  }

  Future<String?> pasteLink(String link) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('onLinkPaste');

    try {
      final HttpsCallableResult result = await callable.call({
        'link': link,
      });
      return result.data as String;
    } catch (e) {
      //print(e);
    }
    return null;
  }

  // setusername
  Future<void> setUsername(String username) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('setUsername');

    try {
      final HttpsCallableResult result = await callable.call({
        'username': username,
      });
    } catch (e) {
      print(e);
    }
  }

// Used as a dev-time helper to test functions
  Future<String?> fetchNews(PlatformType platformType) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('fetchNews');

    try {
      final HttpsCallableResult _ = await callable.call({
        'platformType': platformType.name,
      });
    } catch (e) {
      print(e);
    }
    return null;
  }

  // Used as a dev-time helper to test functions
  Future<String?> triggerTimeFunction(String schedule) async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('triggerTimeFunction');

    try {
      final HttpsCallableResult _ = await callable.call({
        'schedule': schedule,
      });
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future test() async {
    final HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('testFn');

    try {
      final HttpsCallableResult _ = await callable.call({});
    } catch (e) {
      print(e);
    }
    return null;
  }
}
