import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class ProfileIcon extends ConsumerStatefulWidget {
  const ProfileIcon({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final user = ref.selfUserWatch();
    return user.hasValue
        ? CircleAvatar(
            foregroundImage: NetworkImage(user.value!.photoURL!),
            radius: 18,
          )
        : const Icon(FontAwesomeIcons.circle);
  }
}
