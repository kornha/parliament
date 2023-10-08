import 'dart:async';

import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/zrouter.dart';
import 'package:political_think/views/post/post_builder.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class Sharing extends StatefulWidget {
  const Sharing({super.key, required this.child});
  final Widget child;
  @override
  _SharingState createState() => _SharingState();
}

class _SharingState extends State<Sharing> {
  StreamSubscription? _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles;
  // String? _sharedText;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      print("Shared:" + (_sharedFiles?.map((f) => f.path)?.join(",") ?? ""));
    }, onError: (err) {
      //print("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isEmpty) return;

      print(value);
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      print(value);

      ZRouter.rootNavigatorKey.currentContext
          ?.showModal(PostBuilder(url: value));
    }, onError: (err) {
      //print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value == null) return;
      // we use global context since we dont have material ancestor here
      ZRouter.rootNavigatorKey.currentContext
          ?.showModal(PostBuilder(url: value));

      print(value);
    });
  }

  @override
  void dispose() {
    print(_intentDataStreamSubscription);
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
