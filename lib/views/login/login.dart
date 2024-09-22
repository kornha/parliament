import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

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
    return ZScaffold(
      scrollPhysics: const NeverScrollableScrollPhysics(),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Logo(size: context.iconSizeXXL),
            context.sd,
            const LogoText(),
            const Spacer(flex: 20), // hack, change
            TextButton(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Sign in with  "),
                  Icon(FontAwesomeIcons.google),
                ],
              ),
              onPressed: () async {
                Auth().signInWithGoogle().then(
                  (value) {},
                  onError: (e) {
                    context.showFullScreenModal(Text(e.toString()));
                  },
                );
              },
            ),
            context.sf,
          ],
        ),
      ),
    );
  }
}
