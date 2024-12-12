import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/branding_text.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/views/login/login_modal.dart';
import 'package:political_think/views/profile/about.dart';
import 'package:political_think/views/profile/profile.dart';

class Login extends ConsumerStatefulWidget {
  const Login({super.key});

  static const location = "/login";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginState();
}

final providers = [];

class _LoginState extends ConsumerState<Login> {
  @override
  Widget build(BuildContext context) {
    var style = context.d2;

    return ZScaffold(
      scrollPhysics: const NeverScrollableScrollPhysics(),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Logo(size: context.iconSizeXXL),
            const Spacer(flex: 20), // hack, change
            const BrandingText(),
            const Spacer(flex: 20), // hack, change
            ZTextButton(
              type: ZButtonTypes.wide,
              backgroundColor: context.surfaceColor,
              onPressed: () {
                context.showModal(const LoginModal());
              },
              child: const Text("Join"),
            ),
            context.stq,
            ZTextButton(
              type: ZButtonTypes.wide,
              backgroundColor: context.surfaceColor,
              onPressed: () {
                context.showModal(const About());
              },
              child: const Text("About"),
            ),
            context.sf,
          ],
        ),
      ),
    );
  }
}
