import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/views/entity/entity_view.dart';

class ProfileIcon extends ConsumerStatefulWidget {
  final String? url;
  final String? uid;
  final String? eid;
  final double? radius;
  final bool watch;
  final bool isSelf;
  final bool showIfNull;
  final void Function()? onPressed;

  const ProfileIcon({
    super.key,
    this.uid,
    this.eid,
    this.radius,
    this.url,
    // will show self if url or uid is null
    this.isSelf = false,
    this.showIfNull = true,
    this.watch = true,
    this.onPressed,
  });
  // : assert(
  //           // Complex because we allow user, entity, and url to all work
  //           ((url != null ? 1 : 0) +
  //                       (uid != null ? 1 : 0) +
  //                       (eid != null ? 1 : 0)) <=
  //                   1 &&
  //               ((url == null && uid == null && eid == null)
  //                   ? defaultToSelf
  //                   : true),
  //           'At most one of url, uid, or eid can be non-null, and if all are null, defaultToSelf must be true.');

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final user = widget.eid != null || widget.url != null || !widget.isSelf
        ? null
        : widget.uid == null
            ? widget.watch
                ? ref.selfUserWatch().value
                : ref.selfUserRead().value
            : widget.watch
                ? ref.userWatch(widget.uid).value
                : ref.userRead(widget.uid).value;
    final entity =
        widget.eid == null ? null : ref.entityWatch(widget.eid!).value;

    if (!widget.showIfNull &&
        (entity == null && user == null && widget.url == null)) {
      return const SizedBox.shrink();
    }

    return ZTextButton(
      type: ZButtonTypes.icon,
      onPressed: widget.onPressed ??
          (entity != null
              ? () => context.push("${EntityView.location}/${widget.eid}")
              : null),
      child: entity?.photoURL?.isNotEmpty ?? false
          ? CircleAvatar(
              backgroundColor: context.surfaceColor,
              foregroundImage: NetworkImage(entity!.photoURL!),
              radius: widget.radius == null
                  ? context.iconSizeLarge / 2
                  : widget.radius!,
            )
          : (user?.photoURL?.isNotEmpty ?? false) || widget.url != null
              ? CircleAvatar(
                  backgroundColor: context.surfaceColor,
                  foregroundImage: NetworkImage(widget.url ?? user!.photoURL!),
                  radius: widget.radius == null
                      ? context.iconSizeLarge / 2
                      : widget.radius!,
                )
              : CircleAvatar(
                  backgroundColor: context.surfaceColor,
                  radius: widget.radius == null
                      ? context.iconSizeLarge / 2
                      : widget.radius!,
                ),
    );
  }
}
