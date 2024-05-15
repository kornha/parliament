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
    var primaryPostsRef = ref.primaryPostsFromStoriesWatch(widget.sid);
    var primaryPosts = primaryPostsRef.value;
    //
    var postsRef = ref.postsFromStoryWatch(widget.sid);
    var posts = postsRef.value;
    //
    var allPosts = <Post>[...?primaryPosts, ...?posts];

    bool shouldShowSecondaryPosts =
        !(storyRef.isLoading || primaryPostsRef.isLoading) &&
            primaryPosts != null &&
            primaryPosts.length > 1 &&
            (story?.importance ?? 0.5) > 0.1;

    return storyRef.isLoading || primaryPostsRef.isLoading
        ? const Loading(type: LoadingType.post)
        : !primaryPostsRef.hasValue || (primaryPosts?.isEmpty ?? true)
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
                            style: context.l,
                            textAlign: TextAlign.start,
                          ),
                        )
                      : const SizedBox.shrink(),
                  const ZDivider(type: DividerType.SECONDARY),
                  PostItemView(
                    pid: primaryPosts!.first.pid,
                    story: story,
                    showPostButtons: false,
                  ),
                  Visibility(
                      visible: shouldShowSecondaryPosts, child: context.sh),
                  Visibility(
                      visible: shouldShowSecondaryPosts,
                      child: const ZDivider(type: DividerType.SECONDARY)),
                  Visibility(
                      visible: shouldShowSecondaryPosts, child: context.sh),
                  Visibility(
                    visible: shouldShowSecondaryPosts,
                    child: SizedBox(
                      // TODO: MAGIC NUMBER
                      height: context.blockSize.height / 2,
                      child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: allPosts.length - 1, // dont show first!
                          itemBuilder: (context, index) {
                            var post = allPosts[index + 1]; // dont show first!
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
