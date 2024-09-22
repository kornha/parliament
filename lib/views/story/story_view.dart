import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/stats_table.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zicon_text.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/Confidence/Confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/statement/statement_tab_view.dart';
import 'package:political_think/views/statement/statement_view.dart';

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
          ? const Loading(type: LoadingType.postSmall)
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story?.title ?? "",
                    style: context.h3,
                    textAlign: TextAlign.center,
                  ),
                  context.sf,
                  Text(
                    story?.description ?? "",
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
                  context.sh,
                  const ZDivider(type: DividerType.PRIMARY),
                  context.sh,
                  StatsTable(map: {
                    "Newsworthiness": ConfidenceWidget(
                        confidence: story?.newsworthiness,
                        enabled: false,
                        jagged: true),
                    "Avg. Confidence": ConfidenceWidget(
                        confidence: story?.confidence, enabled: false),
                    "Avg. Bias": PoliticalPositionWidget(
                        position: story?.bias, enabled: false),
                    "Avg. Replies":
                        Text(Utils.numToReadableString(story?.avgReplies)),
                    "Avg. Reposts":
                        Text(Utils.numToReadableString(story?.avgReposts)),
                    "Avg. Likes":
                        Text(Utils.numToReadableString(story?.avgLikes)),
                    "Avg. Bookmarks":
                        Text(Utils.numToReadableString(story?.avgBookmarks)),
                    "Avg. Views":
                        Text(Utils.numToReadableString(story?.avgViews)),
                    "Sample Size":
                        Text(Utils.numToReadableString(story?.pids.length)),
                  }),
                  context.sf,
                  const ZDivider(type: DividerType.PRIMARY),
                  StatementTabView(statements: statementsFromStory),
                ],
              ),
            ),
    );
  }
}
