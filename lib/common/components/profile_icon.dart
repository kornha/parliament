import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/extensions.dart';

class ProfileIcon extends ConsumerStatefulWidget {
  final String? url;
  final String? uid;
  final double? size;
  final bool watch;
  final bool defaultToSelf;

  const ProfileIcon({
    super.key,
    this.uid,
    this.size,
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
            radius: widget.size == null ? null : widget.size! / 2,
            // if null defaults to 20, not iconSizeStandard which is 24
            // 20 looks better so I'm keeping it.. not sure why material doesn't use 24 here
            // which seems to be their default size
          )
        : CircleAvatar(
            backgroundColor: context.surfaceColor,
            radius: widget.size == null ? null : widget.size! / 2,
          );
  }
}
