import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class Profile extends ConsumerStatefulWidget {
  const Profile({super.key});

  static const location = "/profile";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<Profile> {
  @override
  Widget build(BuildContext context) {
    return ZScaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Profile"),
                ],
              ),
              onPressed: () async {
                Auth().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
