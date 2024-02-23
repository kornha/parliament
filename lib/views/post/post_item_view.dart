import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/comment_icon.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/location_map.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/services/functions.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_credibility.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:political_think/views/post/post_bias.dart';

class PostItemView extends ConsumerStatefulWidget {
  final String pid;
  final Story? story;
  final bool isSubView;
  final bool showPostButtons;

  const PostItemView({
    super.key,
    required this.pid,
    this.isSubView = false,
    this.story,
    this.showPostButtons = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostItemView> {
  @override
  Widget build(BuildContext context) {
    var storyImportance = widget.story?.importance ?? 5;
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;

    return postRef.isLoading
        ? Loading(
            type: widget.isSubView ? LoadingType.postSmall : LoadingType.post)
        : GestureDetector(
            onTap: () => context.go("${PostView.location}/${post?.pid}"),
            child: !widget.isSubView
                ? Column(
                    children: [
                      Text(
                        post?.title ?? "",
                        textAlign: storyImportance > 9
                            ? TextAlign.center
                            : TextAlign.start,
                        style: storyImportance > 9
                            ? context.h1
                            : storyImportance > 7
                                ? context.h2
                                : context.h3,
                      ),
                      storyImportance > 4
                          ? context.sf
                          : const SizedBox.shrink(),
                      storyImportance > 4
                          ? ZImage(imageUrl: post?.imageUrl ?? "")
                          : const SizedBox.shrink(),
                      context.sf,
                      Text(post?.description ?? "", style: context.m),
                      Visibility(
                          visible: widget.showPostButtons, child: context.sf),
                      Visibility(
                        visible: widget.showPostButtons && post != null,
                        child: PostViewButtons(
                          post: post!,
                          story: widget.story,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ZImage(
                        imageUrl: post?.imageUrl ?? "",
                        imageSize: ZImageSize.small,
                      ),
                      context.sh,
                      SizedBox(
                        height: context.imageSizeSmall.height,
                        // heuristic, trying to match screen size
                        width: context.blockSizeSmall.width -
                            context.imageSizeSmall.width -
                            context.sd.width! -
                            2.0,
                        child: Text(
                          post?.description ?? "",
                          style: (post?.importance ?? 5) > 9
                              ? context.l
                              : (post?.importance ?? 5) > 7
                                  ? context.m
                                  : context.s,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          );
  }
}

class PostViewButtons extends StatelessWidget {
  final Post post;
  final Story? story;
  final bool showMap;
  final bool showCredibility;
  final bool showBias;
  final bool showComments;
  //final bool showComments;

  const PostViewButtons({
    super.key,
    required this.post,
    this.showMap = true,
    this.showCredibility = true,
    this.showBias = true,
    this.showComments = true,
    this.story,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // padding to space evently with post bias
        Visibility(
          visible: showMap,
          child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: (context.iconSizeXXL - context.iconSizeXL) / 2.0),
              child: LocationMap(
                locations: post.locations.isNotEmpty
                    ? post.locations
                    : story?.locations ?? [],
                width: context.iconSizeXL,
                height: context.iconSizeXL,
              )),
        ),
        Visibility(
          visible: showCredibility,
          child: CommentIcon(comments: post.messageCount),
        ),
        // padding to space evently with post bias
        Visibility(
          visible: showCredibility,
          child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: (context.iconSizeXXL - context.iconSizeXL) / 2.0),
              child: PostCredibility(
                post: post,
                height: context.iconSizeXXL,
                width: context.iconSizeXL,
              )),
        ),
        Visibility(
          visible: showBias,
          child: PostBias(
            post: post,
            radius: context.iconSizeXL / 2,
          ),
        ),
      ],
    );
  }
}
