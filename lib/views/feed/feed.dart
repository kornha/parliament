import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/providers/zprovider.dart';
import 'package:political_think/common/services/auth.dart';

class Feed extends ConsumerStatefulWidget {
  const Feed({super.key});

  static const location = "/feed";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FeedState();
}

class _FeedState extends ConsumerState<Feed> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<ZUser?> user = ref.userWatch(ref.authRead.authUser!.uid);
    return Scaffold(
      body: Center(
        child: user.isLoading
            ? Loading()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Sign Out"),
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
