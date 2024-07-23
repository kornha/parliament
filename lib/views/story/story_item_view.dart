import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/location_map.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/extensions.dart';
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
    bool shouldShowPhotos = (story?.photos.length ?? 0) >= 1;
    double importance = story?.importance ?? 0.0;

    return storyRef.isLoading || allPostsRef.isLoading
        ? const Loading(type: LoadingType.post)
        : story == null || !allPostsRef.hasValue || (allPosts?.isEmpty ?? true)
            ? const SizedBox.shrink()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      story.headline != null
                          ? Expanded(
                              flex: 5,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => context.push(
                                      "${StoryView.location}/${story.sid}"),
                                  child: Text(
                                    story.headline!,
                                    style: importance < 0.5
                                        ? context.h5b
                                        : importance < 0.7
                                            ? context.h4b
                                            : importance < 0.9
                                                ? context.h3b
                                                : context.h2b,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      const Spacer(),
                      story.location != null
                          ? LocationMap(location: story.location!)
                          : const SizedBox.shrink(),
                    ],
                  ),
                  context.sh,
                  story.subHeadline != null
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context
                                .push("${StoryView.location}/${story.sid}"),
                            child: Text(
                              story.subHeadline!,
                              style: context.m,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  Visibility(visible: shouldShowPhotos, child: context.sh),
                  Visibility(
                    visible: shouldShowPhotos,
                    child: SizedBox(
                      height: context.blockSize.height,
                      width: context.blockSize.width,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: story.photos.length,
                        itemBuilder: (context, index) {
                          var photo = story.photos[index];
                          return ZImage(photoURL: photo.photoURL);
                        },
                        separatorBuilder: (context, index) =>
                            const ZDivider(type: DividerType.VERTICAL),
                      ),
                    ),
                  ),
                  Visibility(
                      visible: shouldShowSecondaryPosts, child: context.sh),
                  Visibility(
                      visible: shouldShowSecondaryPosts,
                      child: const ZDivider(type: DividerType.SECONDARY)),
                  Visibility(
                    visible: shouldShowSecondaryPosts,
                    child: SizedBox(
                      height: context.blockSizeSmall.height,
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
                            const ZDivider(type: DividerType.VERTICAL),
                      ),
                    ),
                  ),
                ],
              );
  }
}
