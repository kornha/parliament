import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ZAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  ZAppBar({
    super.key,
    this.actions,
    this.leading,
  });
  final Widget? leading;
  final List<Widget>? actions;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ZAppBarState();

  final PreferredSizeWidget appBar = AppBar();

  @override
  Size get preferredSize => appBar.preferredSize;
}

class _ZAppBarState extends ConsumerState<ZAppBar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        widget.leading ?? const SizedBox.shrink(),
        Spacer(),
        ...widget.actions ?? [],
      ],
    );
  }
}
