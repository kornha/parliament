import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/branding.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/constants.dart';

class ZAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  ZAppBar({
    super.key,
    this.leading = const [],
    this.actions = const [],
    this.center,
    this.showBackButton = false,
    this.showLogo = false,
    this.showAppName = false,
  }) : assert(
            !showBackButton && !showAppName && leading.isEmpty ||
                !showBackButton && showAppName && leading.isEmpty ||
                !showBackButton && leading.isNotEmpty && !showAppName ||
                showBackButton && !showAppName && leading.isEmpty,
            "Can only have one or none of backbutton, appname, leading");
  final bool showBackButton;
  final bool showLogo;
  final bool showAppName;
  final List<Widget> actions;
  final List<Widget> leading;
  final Widget? center;

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
                    : const SizedBox.shrink(),
            if (widget.leading.isNotEmpty) ...widget.leading,
            if (widget.leading.isEmpty) const PreRelease(),
            const Spacer(),
            ...widget.actions,
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
