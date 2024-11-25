import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/views/login/login_modal.dart';

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
    var style = context.isDesktop ? context.d1 : context.h3;

    return ZScaffold(
      scrollPhysics: const NeverScrollableScrollPhysics(),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Logo(size: context.iconSizeXL),
            const Spacer(flex: 20), // hack, change
            AnimatedTextKit(
              totalRepeatCount: 10,
              animatedTexts: [
                RandomRevealAnimatedText(
                  "Let's tell the world the truth",
                  textStyle: style,
                  speed: const Duration(
                      milliseconds: 100), // Adjust speed as needed
                ),
                RandomRevealAnimatedText(
                  "Let's tell the world the truth",
                  textStyle: style,
                  speed: const Duration(milliseconds: 100),
                ),
                RandomRevealAnimatedText(
                  "Let's tell the world the truth",
                  textStyle: style,
                  speed: const Duration(milliseconds: 100),
                ),
                RandomRevealAnimatedText(
                  "Parliament",
                  textStyle: style,
                  speed: const Duration(milliseconds: 500),
                ),
              ],
            ),
            const Spacer(flex: 20), // hack, change
            ZTextButton(
              type: ZButtonTypes.wide,
              backgroundColor: context.surfaceColor,
              onPressed: () {
                context.showModal(const LoginModal());
              },
              child: const Text("Join"),
            ),
            context.sf,
            ZTextButton(
              type: ZButtonTypes.wide,
              backgroundColor: context.surfaceColor,
              onPressed: () {
                print("about page");
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

class RandomRevealAnimatedText extends AnimatedText {
  final List<String> characters;
  final Duration scrambleDuration;

  RandomRevealAnimatedText(
    String text, {
    TextStyle? textStyle,
    Duration speed = const Duration(milliseconds: 100),
    this.scrambleDuration = const Duration(milliseconds: 200),
  })  : characters = text.split(''),
        super(
          text: text,
          textStyle: textStyle,
          duration: Duration(
            milliseconds: text.length * speed.inMilliseconds,
          ),
        );

  late Animation<int> _charCountAnimation;
  String _randomLettersCache = '';
  DateTime _lastUpdate = DateTime.now();

  @override
  void initAnimation(AnimationController controller) {
    _charCountAnimation =
        StepTween(begin: 0, end: characters.length).animate(controller);
  }

  void _updateRandomLetters() {
    String randomLetters = '';
    for (int i = _charCountAnimation.value; i < characters.length; i++) {
      String char = characters[i];
      if (char == ' ') {
        randomLetters += ' ';
      } else {
        int randomCharCode = Random().nextInt(26) + 65;
        // Randomly decide uppercase or lowercase
        if (Random().nextBool()) {
          randomCharCode += 32;
        }
        randomLetters += String.fromCharCode(randomCharCode);
      }
    }
    _randomLettersCache = randomLetters;
  }

  @override
  Widget completeText(BuildContext context) => Text(
        text,
        style: textStyle,
      );

  @override
  Widget animatedBuilder(BuildContext context, Widget? child) {
    final int currentCharCount = _charCountAnimation.value;
    String currentText = '';
    if (currentCharCount > 0) {
      currentText = characters.take(currentCharCount).join('');
    }

    if (currentCharCount < characters.length) {
      if (_randomLettersCache.isEmpty ||
          DateTime.now().difference(_lastUpdate) >= scrambleDuration) {
        _updateRandomLetters();
        _lastUpdate = DateTime.now();
      }
      currentText += _randomLettersCache;
    }

    return Text(
      currentText,
      style: textStyle,
    );
  }
}
