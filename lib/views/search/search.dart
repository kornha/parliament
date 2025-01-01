import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key});

  static const location = "/search";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Search", style: context.h1),
            context.sf,
            const Text(
                "Search posts, authors, and stories from on X, IG, NYT, and others."),
            context.sf,
            const Text("Coming Soon!"),
          ],
        ),
      ),
    );
  }
}
