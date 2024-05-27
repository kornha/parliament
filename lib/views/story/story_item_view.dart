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

    return storyRef.isLoading || allPostsRef.isLoading
        ? const Loading(type: LoadingType.post)
        : !allPostsRef.hasValue || (allPosts?.isEmpty ?? true)
            ? const SizedBox.shrink()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      story?.title != null
                          ? GestureDetector(
                              onTap: () => context
                                  .push("${StoryView.location}/${story.sid}"),
                              child: Text(
                                story!.title!,
                                style: context.mb.copyWith(
                                    color: context.surfaceColorBright),
                                textAlign: TextAlign.start,
                              ),
                            )
                          : const SizedBox.shrink(),
                      const Spacer(),
                      Visibility(
                        visible: story?.location != null,
                        child: LocationMap(
                            location: story!.location!,
                            size: context.iconSizeLarge),
                      )
                    ],
                  ),
                  context.sh,
                  story.description != null
                      ? GestureDetector(
                          onTap: () => context
                              .push("${StoryView.location}/${story.sid}"),
                          child: Text(
                            story.latest!,
                            style: context.l,
                            textAlign: TextAlign.start,
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
                            const ZDivider(type: DividerType.VERTICAL),
                      ),
                    ),
                  ),
                ],
              );
  }
}
