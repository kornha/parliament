import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';

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
    var claimsRef = ref.claimsFromStoriesWatch(widget.sid);
    var claims = claimsRef.value;

    return ZScaffold(
      appBar: ZAppBar(showBackButton: true),
      body: storyRef.isLoading
          ? const Loading(type: LoadingType.postSmall)
          : Column(
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
                const ZDivider(type: DividerType.PRIMARY),
                context.sf,
                claims?.isNotEmpty ?? false
                    ? Column(
                        children: claims!
                            .map((claim) => Column(
                                  children: [
                                    Text(
                                      claim.value,
                                      style: context.l,
                                    ),
                                    context.sh,
                                    Row(
                                      children: [
                                        Text(
                                          "${claim.pro.length}",
                                          style: context.al.copyWith(
                                              color: context.secondaryColor),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${claim.against.length}",
                                          style: context.al.copyWith(
                                              color: context.errorColor),
                                        ),
                                      ],
                                    ),
                                    const ZDivider(type: DividerType.SECONDARY),
                                  ],
                                ))
                            .toList(),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
    );
  }
}
