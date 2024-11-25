import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';

class LoginModal extends StatelessWidget {
  const LoginModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ZTextButton(
          type: ZButtonTypes.wide,
          backgroundColor: context.secondaryColor,
          foregroundColor: context.onSecondaryColor,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sign in with  "),
              Icon(FontAwesomeIcons.google),
            ],
          ),
          onPressed: () async {
            Auth.instance().signInWithGoogle().then(
              (value) {
                context.pop();
              },
              onError: (e) {
                context.showFullScreenModal(Text(e.toString()));
              },
            );
          },
        ),
        context.sh,
        const ZDivider(type: DividerType.TERTIARY),
        context.sh,
        ZTextButton(
          type: ZButtonTypes.wide,
          backgroundColor: context.secondaryColor,
          foregroundColor: context.onSecondaryColor,
          child: const Text("Sign in with Email"),
        ),
        const ZTextButton(
          type: ZButtonTypes.wide,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sign in with  "),
              Icon(FontAwesomeIcons.github),
            ],
          ),
        ),
        // context.sf,
        // const ZTextButton(
        //   type: ZButtonTypes.wide,
        //   child: Text("Login with Email (Coming Soon)"),
        // ),
      ],
    );
  }
}

            // TextButton(
            //   child: const Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Text("Sign in with  "),
            //       Icon(FontAwesomeIcons.google),
            //     ],
            //   ),
            //   onPressed: () async {
            //     Auth.instance().signInWithGoogle().then(
            //       (value) {},
            //       onError: (e) {
            //         context.showFullScreenModal(Text(e.toString()));
            //       },
            //     );
            //   },
            // ),
