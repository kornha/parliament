import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:political_think/common/chat/src/util.dart';
import 'package:political_think/common/components/confidence_component.dart';
import 'package:political_think/common/components/political_position_component.dart';
import 'package:political_think/common/components/zicon_text.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/views/login/login.dart';
import 'package:political_think/views/profile/about.dart';
import 'package:political_think/views/search/search.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PreRelease extends StatelessWidget {
  const PreRelease({super.key});

  @override
  Widget build(BuildContext context) {
    return ZTextButton(
      type: ZButtonTypes.area,
      onPressed: () => context.showModal(const About()),
      foregroundColor: context.secondaryColor,
      child: Text(
        "Pre-Release",
        style: context.mb.copyWith(
          color: context.secondaryColor,
        ),
      ),
    );
  }
}

class DownloapApp extends StatelessWidget {
  const DownloapApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ZTextButton(
      type: ZButtonTypes.area,
      onPressed: () {
        //TODO: add android
        launchUrlString(
            "https://apps.apple.com/us/app/parliament-foundation/id6479275256");
      },
      foregroundColor: context.secondaryColor,
      child: ZIconText(
        icon: FontAwesomeIcons.apple,
        style: context.mb.copyWith(
          color: context.secondaryColor,
        ),
        text: "App",
      ),
    );
  }
}

class JoinAppBarButton extends StatelessWidget {
  const JoinAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ZTextButton(
      type: ZButtonTypes.area,
      onPressed: () => context
          .go(Login.location), // .go instead of route to push over nav bar
      foregroundColor: context.secondaryColor,
      child: Text(
        "Join",
        style: context.mb.copyWith(
          color: context.secondaryColor,
        ),
      ),
    );
  }
}

class BrandingPuzzleText extends StatelessWidget {
  const BrandingPuzzleText({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Make this scale with screen size
    var style = isMobile ? context.h1 : context.d2;

    return Stack(
      alignment: Alignment.center,
      children: [
        ConfidenceComponent(
          horizontal: true,
          width: context.blockSizeSmall.width,
          height: context.blockSizeSmall.height,
          confidence: Confidence.max(),
        ),
        Container(
          padding: context.pf,
          width: context.blockSizeSmall.width,
          child: AnimatedTextKit(
            totalRepeatCount: 10,
            animatedTexts: [
              RandomRevealAnimatedText(
                "Let's tell\nthe world\nthe truth",
                textStyle: style,
                speed:
                    const Duration(milliseconds: 100), // Adjust speed as needed
              ),
              RandomRevealAnimatedText(
                "Let's tell\nthe world\nthe truth",
                textStyle: style,
                speed: const Duration(milliseconds: 100),
              ),
              RandomRevealAnimatedText(
                "Let's tell\nthe world\nthe truth",
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
        ),
      ],
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
    for (int i = 0; i < characters.length; i++) {
      if (i < _charCountAnimation.value) {
        // Revealed characters
        randomLetters += characters[i];
      } else {
        String char = characters[i];
        if (char == ' ') {
          randomLetters += ' ';
        } else if (char == '\n') {
          // Maintain the newline position with a placeholder (e.g., space)
          randomLetters += '\n';
        } else {
          int randomCharCode = Random().nextInt(26) + 65;
          // Randomly decide uppercase or lowercase
          if (Random().nextBool()) {
            randomCharCode += 32;
          }
          randomLetters += String.fromCharCode(randomCharCode);
        }
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
    if (_randomLettersCache.isEmpty ||
        DateTime.now().difference(_lastUpdate) >= scrambleDuration) {
      _updateRandomLetters();
      _lastUpdate = DateTime.now();
    }

    return Text(
      _randomLettersCache,
      style: textStyle,
    );
  }
}
