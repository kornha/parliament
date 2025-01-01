import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class Maps extends ConsumerStatefulWidget {
  const Maps({super.key});

  static const location = "/maps";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MapsState();
}

class _MapsState extends ConsumerState<Maps> {
  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Interactive Maps", style: context.h1),
            context.sf,
            const Text("Coming Soon!"),
          ],
        ),
      ),
    );
  }
}
