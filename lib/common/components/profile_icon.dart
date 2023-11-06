import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class ProfileIcon extends ConsumerStatefulWidget {
  const ProfileIcon({
    super.key,
    this.uid,
    this.size = IconSize.standard,
  });
  final String? uid;
  final double size;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final user =
        widget.uid == null ? ref.selfUserWatch() : ref.userWatch(widget.uid);
    return user.value?.photoURL != null
        ? CircleAvatar(
            foregroundImage: NetworkImage(user.value?.photoURL ?? ''),
            radius: widget.size,
          )
        : const Icon(FontAwesomeIcons.circle);
  }
}
