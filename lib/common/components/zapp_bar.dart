import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/extensions.dart';

class ZAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  ZAppBar({
    super.key,
    this.actions,
    this.leading,
    this.center,
    this.showBackButton = false,
    this.showAppName = false,
  });
  final bool showBackButton;
  final bool showAppName;
  final Widget? leading;
  final Widget? center;
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.showBackButton
                ? const ZBackButton()
                : widget.leading ?? const SizedBox.shrink(),
            const Spacer(),
            ...widget.actions ?? [],
          ],
        ),
        Center(
          child: widget.showAppName
              ? Text("PARLIAMENT",
                  style: context.d, textAlign: TextAlign.center)
              : widget.center ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}
