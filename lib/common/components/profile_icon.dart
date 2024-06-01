import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/extensions.dart';

class ProfileIcon extends ConsumerStatefulWidget {
  final String? url;
  final String? uid;
  final double? radius;
  final bool watch;
  final bool defaultToSelf;

  const ProfileIcon({
    super.key,
    this.uid,
    this.radius,
    this.url,
    // will show self if url or uid is null
    this.defaultToSelf = true,
    this.watch = true,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final user = widget.url != null || !widget.defaultToSelf
        ? null
        : widget.uid == null
            ? widget.watch
                ? ref.selfUserWatch()
                : ref.selfUserRead()
            : widget.watch
                ? ref.userWatch(widget.uid)
                : ref.userRead(widget.uid);

    return (user?.value?.photoURL?.isNotEmpty ?? false) || widget.url != null
        ? CircleAvatar(
            backgroundColor: context.surfaceColor,
            foregroundImage: NetworkImage(widget.url ?? user!.value!.photoURL!),
            radius: widget.radius == null
                ? context.iconSizeLarge / 2
                : widget.radius!,
          )
        : CircleAvatar(
            backgroundColor: context.surfaceColor,
            radius: widget.radius == null
                ? context.iconSizeLarge / 2
                : widget.radius!,
          );
  }
}
