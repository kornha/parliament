import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_item_view.dart';

class StoryView extends ConsumerStatefulWidget {
  const StoryView({
    super.key,
    required this.sid,
  });

  final String sid;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StoryViewState();
}

class _StoryViewState extends ConsumerState<StoryView> {
  @override
  Widget build(BuildContext context) {
    var storyRef = ref.storyWatch(widget.sid);
    var story = storyRef.value;
    //
    var postsRef = ref.postsFromStoriesWatch(widget.sid);
    var posts = postsRef.value;
    //
    bool shouldShowSecondaryPosts =
        !(storyRef.isLoading || postsRef.isLoading) &&
            posts != null &&
            posts.length > 1 &&
            (story?.importance ?? 0.5) > 0.1;

    return storyRef.isLoading || postsRef.isLoading
        ? const Loading(type: LoadingType.post)
        : !postsRef.hasValue || (posts?.isEmpty ?? true)
            ? const SizedBox.shrink()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PostItemView(
                    pid: posts!.first.pid,
                    story: story,
                    showPostButtons: true,
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
                      height: context.blockSize.height,
                      child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: posts.length - 1, // dont show first!
                          itemBuilder: (context, index) {
                            var post = posts[index + 1]; // dont show first!
                            return Container(
                                child: PostItemView(
                              pid: post.pid,
                              story: story,
                              isSubView: true,
                              showPostButtons: true,
                            ));
                          },
                          separatorBuilder: (context, index) =>
                              const ZDivider(type: DividerType.VERTICAL)),
                    ),
                  ),
                ],
              );
  }
}
