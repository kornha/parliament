import 'package:flutter/material.dart';
import 'package:political_think/common/components/confidence_component.dart';
import 'package:political_think/common/components/political_position_component.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoView extends StatelessWidget {
  final Widget leading;
  final String title;
  final String type;
  final String description;
  final String? learnMoreLabel;
  final String? learnMoreUrl;
  final Color? accentColor;
  final bool showLearnMoreIfUrlIsPresent;

  const InfoView({
    super.key,
    required this.leading,
    required this.type,
    required this.title,
    required this.description,
    required this.learnMoreLabel,
    required this.learnMoreUrl,
    required this.accentColor,
    this.showLearnMoreIfUrlIsPresent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            leading,
            context.sf,
            Text(
              title,
              style: context.h1,
            ),
          ],
        ),
        context.sf,
        Text(
          type,
          style: context.h1.copyWith(color: context.surfaceColor),
        ),
        context.sf,
        Text(
          description,
          style: context.m,
        ),
        context.sf,
        if (learnMoreUrl != null && showLearnMoreIfUrlIsPresent)
          ZTextButton(
            type: ZButtonTypes.wide,
            foregroundColor: accentColor,
            onPressed: () {
              if (learnMoreUrl == null) return;
              final Uri url = Uri.parse(learnMoreUrl!);
              launchUrl(url);
            },
            child: Text(learnMoreLabel ?? "Learn More"),
          ),
      ],
    );
  }
}

class PoliticalPositionView extends StatelessWidget {
  final PoliticalPosition? position;
  const PoliticalPositionView({
    super.key,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    final title = position?.name != null ? position!.name : "N/A";

    const description =
        "Bias measures the political position of a statement or entity. It is an angular "
        "grouping of statements or entities based on statements that other entities have "
        "made, pinned so that 'conservative' is at the right side.\n\n"
        "Practically speaking, right equates to conservative, left to liberal, top to moderate, "
        "and bottom to extreme.";

    return InfoView(
      leading: PoliticalPositionComponent(
        position: position,
        radius: context.iconSizeXL / 2,
      ),
      title: title,
      type: "bias",
      description: description,
      learnMoreLabel: "Learn More About Bias",
      learnMoreUrl:
          "https://github.com/kornha/parliament?tab=readme-ov-file#bias",
      accentColor: position?.color,
    );
  }
}

class NewsworthinessView extends StatelessWidget {
  final Confidence? newsworthiness;
  const NewsworthinessView({
    super.key,
    this.newsworthiness,
  });

  @override
  Widget build(BuildContext context) {
    final title = newsworthiness?.newsworthyName ?? "N/A";

    const description =
        "Newsworthiness measures the importance of a Story from 0.0 - 1.0. Newsworthiness is calculated by finding the virality of content, and scaling it by the bias and confidence of the sources. Stories that are shared by many political positions are considered more newsworthy than those shared by only a few.\n\nThis allows news to be ranked by perceived importance across views, and not by one view spamming content to create urgency.";

    return InfoView(
      leading: ConfidenceComponent(
        confidence: newsworthiness,
        height: context.iconSizeXL,
        width: context.iconSizeXL,
        wave: true,
        showText: true,
      ),
      title: title,
      type: "newsworthiness",
      description: description,
      learnMoreLabel: "Learn More About Newsworthiness",
      learnMoreUrl:
          "https://github.com/kornha/parliament?tab=readme-ov-file#newsworthiness",
      accentColor: newsworthiness?.color,
    );
  }
}

class ViralityView extends StatelessWidget {
  final Confidence? virality;
  const ViralityView({
    super.key,
    this.virality,
  });

  @override
  Widget build(BuildContext context) {
    final title = virality?.viralName ?? "N/A";

    const description =
        "Virality is a score 0.0 - 1.0 of how much something online is interacted with. Virality is calculated by finding the number of likes, replies, bookmarks, reposts, views, and adjusting them for platform average, user average, and global averages.\n\nVirality ignores bias and confidence, and purely measures internet traction. It is a key component in calculating Newsworthiness.";

    return InfoView(
      leading: ConfidenceComponent(
        confidence: virality,
        height: context.iconSizeXL,
        width: context.iconSizeXL,
        viral: true,
        showText: true,
      ),
      title: title,
      type: "virality",
      description: description,
      learnMoreLabel: "Learn More About Virality",
      learnMoreUrl:
          "https://github.com/kornha/parliament?tab=readme-ov-file#newsworthiness",
      accentColor: virality?.color,
    );
  }
}

class ConfidenceView extends StatelessWidget {
  final Confidence? confidence;
  const ConfidenceView({
    super.key,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final title = confidence?.name ?? "N/A";

    const description =
        "Confidence is a score from 0.0 - 1.0 that measures how likely something is true based on how true it or its sources have been in the past. Confidence is calculated like a credit score, by recording the history of accuracy of an Entity, and then assigning the Claims made by an Entity a confidence. This allows for an immediate scoring of the confidence of news, and also allows for the tracking of the accuracy of sources over time.\n\nConfidence scores are subject to change, and improve in accuracy as more data is collected.";

    return InfoView(
      leading: ConfidenceComponent(
        confidence: confidence,
        height: context.iconSizeXL,
        width: context.iconSizeXL,
        showText: true,
      ),
      title: title,
      type: "confidence",
      description: description,
      learnMoreLabel: "Learn More About Confidence",
      learnMoreUrl:
          "https://github.com/kornha/parliament?tab=readme-ov-file#confidence",
      accentColor: confidence?.color,
    );
  }
}
