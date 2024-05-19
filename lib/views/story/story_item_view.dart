import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_item_view.dart';
import 'package:political_think/views/story/story_view.dart';

class StoryItemView extends ConsumerStatefulWidget {
  const StoryItemView({
    super.key,
    required this.sid,
  });

  final String sid;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StoryViewState();
}

class _StoryViewState extends ConsumerState<StoryItemView> {
  @override
  Widget build(BuildContext context) {
    var storyRef = ref.storyWatch(widget.sid);
    var story = storyRef.value;
    //
    // var primaryPostsRef = ref.primaryPostsFromStoriesWatch(widget.sid);
    // var primaryPosts = primaryPostsRef.value;

    var allPostsRef = ref.postsFromStoryWatch(widget.sid);
    var allPosts = allPostsRef.value;

    bool shouldShowSecondaryPosts = (allPosts?.length ?? 0) >= 1;

    return storyRef.isLoading || allPostsRef.isLoading
        ? const Loading(type: LoadingType.post)
        : !allPostsRef.hasValue || (allPosts?.isEmpty ?? true)
            ? const SizedBox.shrink()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  story?.title != null
                      ? GestureDetector(
                          onTap: () =>
                              context.go("${StoryView.location}/${story.sid}"),
                          child: Text(
                            story!.title!,
                            style: context.lb,
                            textAlign: TextAlign.start,
                          ),
                        )
                      : const SizedBox.shrink(),
                  const ZDivider(type: DividerType.SECONDARY),
                  story?.description != null
                      ? GestureDetector(
                          onTap: () =>
                              context.go("${StoryView.location}/${story.sid}"),
                          child: Text(
                            story!.description!,
                            style: context.l,
                            textAlign: TextAlign.start,
                          ),
                        )
                      : const SizedBox.shrink(),
                  Visibility(
                      visible: shouldShowSecondaryPosts, child: context.sh),
                  Visibility(
                      visible: shouldShowSecondaryPosts,
                      child: const ZDivider(type: DividerType.SECONDARY)),
                  Visibility(
                    visible: shouldShowSecondaryPosts,
                    child: SizedBox(
                      height: context.blockSize.height / 2,
                      child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: allPosts!.length,
                          itemBuilder: (context, index) {
                            var post = allPosts[index];
                            return PostItemView(
                              pid: post.pid,
                              story: story,
                              isSubView: true,
                              showPostButtons: false,
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const ZDivider(type: DividerType.VERTICAL)),
                    ),
                  ),
                ],
              );
  }
}
