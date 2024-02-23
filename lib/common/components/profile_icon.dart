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
    this.size,
    this.watch = true,
  });
  final String? uid;
  final double? size;
  final bool watch;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final user = widget.uid == null
        ? widget.watch
            ? ref.selfUserWatch()
            : ref.selfUserRead()
        : widget.watch
            ? ref.userWatch(widget.uid)
            : ref.userRead(widget.uid);
    return user.value?.photoURL?.isNotEmpty ?? false
        ? CircleAvatar(
            backgroundColor: context.surfaceColor,
            foregroundImage: NetworkImage(user.value!.photoURL!),
            radius: widget.size ?? context.iconSizeStandard,
          )
        : const Icon(FontAwesomeIcons.circle);
  }
}
