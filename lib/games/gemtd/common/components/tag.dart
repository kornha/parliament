import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

class Tag extends StatelessWidget {
  const Tag({super.key, required this.type});

  final CityType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: type.color(),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: context.pl.copyWith(top: 1, bottom: 1),
      child: Text(
        type.name,
        style: TextStyle(color: type.secondaryColor(), fontSize: 12),
      ),
    );
  }
}

class StatsTag extends StatelessWidget {
  const StatsTag({super.key, required this.text, required this.subtext});

  final String text;
  final String subtext;

  @override
  Widget build(BuildContext context) {
    return StatsTagBase(
      text: text,
      sub: Text(
        subtext,
        style: TextStyle(color: Palette.white, fontSize: 13),
      ),
    );
  }
}

class StatsTagBase extends StatelessWidget {
  const StatsTagBase({super.key, required this.text, required this.sub});

  final String text;
  final Widget sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Decorations.boxDecoration,
      padding: context.pq.copyWith(top: 2, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(color: Palette.lightSlate, fontSize: 13),
          ),
          context.sh,
          sub,
        ],
      ),
    );
  }
}

class StatsTagButton extends StatelessWidget {
  const StatsTagButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.sub,
    this.row = true,
  });

  final bool row;
  final String text;
  final Widget sub;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Decorations.boxDecoration,
      child: TextButton(
        onPressed: onPressed,
        child: Flex(
          direction: row ? Axis.horizontal : Axis.vertical,
          mainAxisSize: row ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: row
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              text,
              style: const TextStyle(color: Palette.lightSlate, fontSize: 13),
            ),
            context.sh,
            sub,
          ],
        ),
      ),
    );
  }
}

class StatsTagTextButton extends StatelessWidget {
  const StatsTagTextButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 33,
      decoration: Decorations.boxDecoration,
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(color: Palette.lightSlate, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
