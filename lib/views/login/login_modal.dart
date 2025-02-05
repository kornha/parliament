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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sign in with  ",
                  style: context.m.copyWith(color: context.onSecondaryColor)),
              Icon(FontAwesomeIcons.google, color: context.onSecondaryColor),
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
        context.stq,
        ZTextButton(
          type: ZButtonTypes.wide,
          backgroundColor: context.backgroundColor,
          foregroundColor: context.onBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sign in with  ",
                  style: context.m.copyWith(color: context.onBackgroundColor)),
              Icon(FontAwesomeIcons.apple, color: context.onBackgroundColor),
            ],
          ),
          onPressed: () async {
            Auth.instance().signInWithApple().then(
              (value) {
                context.pop();
              },
              onError: (e) {
                context.showFullScreenModal(Text(e.toString()));
              },
            );
          },
        ),
        // Removed due to app store rejection
        // context.sh,
        // const ZDivider(type: DividerType.TERTIARY),
        // ZTextButton(
        //   type: ZButtonTypes.wide,
        //   backgroundColor: context.secondaryColor,
        //   foregroundColor: context.onSecondaryColor,
        //   child: const Text("Sign in with Email"),
        // ),
        // context.sh,
        // const ZTextButton(
        //   type: ZButtonTypes.wide,
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Text("Sign in with  "),
        //       Icon(FontAwesomeIcons.github),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
