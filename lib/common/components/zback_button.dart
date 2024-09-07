import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';
import 'package:political_think/common/extensions.dart';

//TODO: Not used, deprecated?
class ZBackButton extends StatelessWidget {
  const ZBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: context.iconSizeStandard,
      icon: const Icon(FontAwesomeIcons.chevronLeft),
      color: context.primaryColor,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          // TODO: Hack! above should work but doesn't?
          context.go('/');
        }
      },
    );
  }
}
