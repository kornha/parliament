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
  final bool defaultToSelf;
  final void Function()? onPressed;

  const ProfileIcon({
    super.key,
    this.uid,
    this.eid,
    this.radius,
    this.url,
    // will show self if url or uid is null
    this.defaultToSelf = true,
    this.watch = true,
    this.onPressed,
  }) : assert(
            // Complex because we allow user, entity, and url to all work
            ((url != null ? 1 : 0) +
                        (uid != null ? 1 : 0) +
                        (eid != null ? 1 : 0)) <=
                    1 &&
                ((url == null && uid == null && eid == null)
                    ? defaultToSelf
                    : true),
            'At most one of url, uid, or eid can be non-null, and if all are null, defaultToSelf must be true.');

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZScaffoldState();
}

class _ZScaffoldState extends ConsumerState<ProfileIcon> {
  @override
  Widget build(BuildContext context) {
    final user =
        widget.eid != null || widget.url != null || !widget.defaultToSelf
            ? null
            : widget.uid == null
                ? widget.watch
                    ? ref.selfUserWatch()
                    : ref.selfUserRead()
                : widget.watch
                    ? ref.userWatch(widget.uid)
                    : ref.userRead(widget.uid);
    final entity = widget.eid == null ? null : ref.entityWatch(widget.eid!);

    return ZTextButton(
      type: ZButtonTypes.icon,
      onPressed: widget.onPressed ??
          (entity != null
              ? () => context.push("${EntityView.location}/${widget.eid}")
              : null),
      child: entity?.value?.photoURL?.isNotEmpty ?? false
          ? CircleAvatar(
              backgroundColor: context.surfaceColor,
              foregroundImage: NetworkImage(entity!.value!.photoURL!),
              radius: widget.radius == null
                  ? context.iconSizeLarge / 2
                  : widget.radius!,
            )
          : (user?.value?.photoURL?.isNotEmpty ?? false) || widget.url != null
              ? CircleAvatar(
                  backgroundColor: context.surfaceColor,
                  foregroundImage:
                      NetworkImage(widget.url ?? user!.value!.photoURL!),
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
