import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class Games extends ConsumerStatefulWidget {
  const Games({super.key});

  static const location = "/games";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GamesState();
}

class _GamesState extends ConsumerState<Games> {
  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Games", style: context.h1),
            context.sf,
            const Text("Coming Soon!"),
          ],
        ),
      ),
    );
  }
}
