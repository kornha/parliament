import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:political_think/games/gemtd/common/components/tag.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/game_stats.dart';

class StatsRow extends StatelessWidget {
  final GameStats stats;

  const StatsRow({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatsTag(
          text: "Capital",
          subtext: Utils.getFormattedCapital(stats.capital),
        ),
        StatsTag(
          text: "Wave",
          subtext: stats.wave.toString(),
        ),
        StatsTag(
          text: "Score",
          subtext: Utils.getFormattedCapital(stats.maxCapital),
        ),
        const Spacer(),
      ],
    );
  }
}
