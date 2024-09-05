import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zicon_text.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/util/utils.dart';
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
                      ZIconText(
                          icon: FontAwesomeIcons.triangleExclamation,
                          text: story?.importance?.toString() ?? ""),
                    ],
                  ),
                  const ZDivider(type: DividerType.PRIMARY),
                  StatementTabView(statements: statementsFromStory),
                ],
              ),
            ),
    );
  }
}
