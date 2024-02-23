import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

class ZAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  ZAppBar({
    super.key,
    this.actions,
    this.leading,
    this.center,
    this.showBackButton = false,
    this.showLogo = false,
    this.showAppName = false,
  });
  final bool showBackButton;
  final bool showLogo;
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
                : widget.showAppName
                    // TODO: Padding because IconButton ZBackButton is padded
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: Margins.half),
                        child: LogoName(),
                      )
                    // TODO: Padding because IconButton in ZBackButton is padded
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Margins.half),
                        child: widget.leading ?? const SizedBox.shrink(),
                      ),
            const Spacer(),
            ...widget.actions ?? [],
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.showLogo
                ? const Logo()
                : widget.center ?? const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }
}
