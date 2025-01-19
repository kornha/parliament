import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/stats_table.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zexpansion_tile.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/confidence/confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/statement/statement_tab_view.dart';

class StoryView extends ConsumerStatefulWidget {
  final String sid;

  const StoryView({
    super.key,
    required this.sid,
  });

  static const location = '/story';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StoryViewState();
}

class _StoryViewState extends ConsumerState<StoryView> {
  // mixin needed for tab controller

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var storyRef = ref.storyWatch(widget.sid);
    var story = storyRef.value;

    var statementsFromStoryRef =
        ref.watch(statementsFromStoryProvider(widget.sid));
    var statementsFromStory = statementsFromStoryRef.value;

    return ZScaffold(
      appBar: ZAppBar(showBackButton: true),
      body: storyRef.isLoading
          ? const Loading()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    story?.title ?? "",
                    style: context.h3,
                    textAlign: TextAlign.center,
                  ),
                ),
                context.sf,
                Text(
                  story?.lede ?? "",
                  style: context.l,
                ),
                context.sf,
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      Utils.toHumanReadableDate(story?.happenedAt),
                      style: context.m.copyWith(
                        color: context.secondaryColor,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const ZDivider(type: DividerType.PRIMARY),
                StatementTabView(statements: statementsFromStory),
                const ZDivider(type: DividerType.SECONDARY),
                if (story?.article != null)
                  ZExpansionTile(
                    initiallyExpanded: true,
                    title: Text(story!.headline!, style: context.h4),
                    subtitle: const Text("article"),
                    children: [
                      Text(
                        story.article!,
                        style: context.l,
                      ),
                    ],
                  ),
                ZExpansionTile(
                  initiallyExpanded: true,
                  title: Text("Primary indicators", style: context.h4),
                  subtitle: const Text("stats"),
                  children: [
                    StatsTable(map: {
                      "Newsworthiness": ConfidenceWidget(
                          confidence: story!.newsworthiness,
                          enabled: false,
                          wave: true),
                      "Avg. Confidence": ConfidenceWidget(
                          confidence: story.confidence, enabled: false),
                      "Avg. Bias": PoliticalPositionWidget(
                          position: story.bias, enabled: false),
                      "Virality": ConfidenceWidget(
                        confidence: story.virality,
                        viral: true,
                        enabled: false,
                      ),
                      "NewsworthyAt":
                          Text(Utils.toHumanReadableDate(story.newsworthyAt)),
                      "HappenedAt": Text(
                        Utils.toHumanReadableDate(story.happenedAt),
                      ),
                      "Avg. Replies":
                          Text(Utils.numToReadableString(story.avgReplies)),
                      "Avg. Reposts":
                          Text(Utils.numToReadableString(story.avgReposts)),
                      "Avg. Likes":
                          Text(Utils.numToReadableString(story.avgLikes)),
                      "Avg. Bookmarks":
                          Text(Utils.numToReadableString(story.avgBookmarks)),
                      "Avg. Views":
                          Text(Utils.numToReadableString(story.avgViews)),
                      "Sample Size":
                          Text(Utils.numToReadableString(story.pids.length)),
                    }),
                  ],
                ),
                if (story.description != null)
                  ZExpansionTile(
                      initiallyExpanded: false,
                      title: Text("Description", style: context.h4),
                      subtitle: const Text("aggregated from posts"),
                      children: [
                        Text(
                          story.description ?? "",
                          style: context.l,
                        ),
                      ]),
              ],
            ),
    );
  }
}
