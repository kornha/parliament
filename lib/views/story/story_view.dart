import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/claim/claim_view.dart';

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
  @override
  Widget build(BuildContext context) {
    var storyRef = ref.storyWatch(widget.sid);
    var story = storyRef.value;

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
                      Icon(FontAwesomeIcons.triangleExclamation,
                          size: context.iconSizeSmall,
                          color: context.secondaryColor),
                      context.sq,
                      Text(
                        story?.importance?.toString() ?? "",
                        style: context.m.copyWith(
                          color: context.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  context.sf,
                  const ZDivider(type: DividerType.PRIMARY),
                  context.sh,
                  story?.cids.isNotEmpty ?? false
                      ? Column(
                          children: story!.cids.asMap().entries.expand((entry) {
                            int index = entry.key;
                            var cid = entry.value;
                            return [
                              ClaimView(cid: cid),
                              if (index != story.cids.length - 1)
                                const ZDivider(type: DividerType.SECONDARY),
                            ];
                          }).toList(),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
    );
  }
}
