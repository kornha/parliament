import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zicon_text.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_view.dart';

class PostItemView extends ConsumerStatefulWidget {
  final String pid;
  final Story? story;
  final bool isSubView;
  final bool gestureDetection;

  const PostItemView({
    super.key,
    required this.pid,
    this.isSubView = false,
    this.story,
    this.gestureDetection = true,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostItemView> {
  @override
  Widget build(BuildContext context) {
    var storyNewsworthiness = widget.story?.newsworthiness?.value ?? 0.5;
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;

    AsyncValue<Entity?>? entityRef;
    if (post?.eid != null) {
      entityRef = ref.entityWatch(post!.eid!);
    }
    var entity = entityRef?.value;

    AsyncValue<Platform?>? platformRef;
    if (post?.plid != null) {
      platformRef = ref.platformWatch(post!.plid!);
    }
    var platform = platformRef?.value;

    return postRef.isLoading
        ? Loading(
            type: widget.isSubView ? LoadingType.postSmall : LoadingType.post)
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: !widget.gestureDetection
                  ? null
                  : () =>
                      // See if current location == PostView.location
                      // Is there a better way to do this?
                      context.currentLocation.contains(PostView.location)
                          ? null
                          : context.route("${PostView.location}/${post?.pid}"),
              child: !widget.isSubView
                  ? Column(
                      children: [
                        Row(
                          children: [
                            ProfileIcon(
                              eid: entity?.eid,
                              plid: platform?.plid,
                            ),
                          ],
                        ),
                        context.sh,
                        Text(
                          post?.title ?? "",
                          textAlign: storyNewsworthiness > 0.9
                              ? TextAlign.center
                              : TextAlign.start,
                          style: storyNewsworthiness > 0.9
                              ? context.h2
                              : storyNewsworthiness > 0.7
                                  ? context.h3
                                  : context.l,
                        ),
                        storyNewsworthiness > 0.0
                            ? context.sf
                            : const SizedBox.shrink(),
                        storyNewsworthiness > 0.0 &&
                                post?.photo?.photoURL != null
                            ? ZImage(photoURL: post?.photo?.photoURL ?? "")
                            : const SizedBox.shrink(),
                        storyNewsworthiness > 0.0 &&
                                post?.photo?.photoURL != null
                            ? context.sf
                            : const SizedBox.shrink(),
                        Visibility(
                            visible: post?.body != null &&
                                (post!.body?.isNotEmpty ?? false),
                            child: Text(post?.body ?? "", style: context.m)),
                        Visibility(
                            visible: post?.body != null &&
                                (post!.body?.isNotEmpty ?? false),
                            child: context.sf),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Visibility(
                              visible: post?.replies != null,
                              child: ZIconText(
                                  icon: FontAwesomeIcons.comment,
                                  text:
                                      Utils.numToReadableString(post?.replies)),
                            ),
                            Visibility(
                              visible: post?.reposts != null,
                              child: ZIconText(
                                  icon: FontAwesomeIcons.retweet,
                                  text:
                                      Utils.numToReadableString(post?.reposts)),
                            ),
                            Visibility(
                              visible: post?.likes != null,
                              child: ZIconText(
                                  icon: FontAwesomeIcons.heart,
                                  text: Utils.numToReadableString(post?.likes)),
                            ),
                            Visibility(
                              visible: post?.bookmarks != null,
                              child: ZIconText(
                                  icon: FontAwesomeIcons.bookmark,
                                  text: Utils.numToReadableString(
                                      post?.bookmarks)),
                            ),
                            Visibility(
                              visible: post?.views != null,
                              child: ZIconText(
                                  icon: FontAwesomeIcons.eye,
                                  text: Utils.numToReadableString(post?.views)),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        post?.photo?.photoURL != null
                            ? ZImage(
                                photoURL: post?.photo?.photoURL ?? "",
                                imageSize: ZImageSize.small,
                              )
                            : const SizedBox.shrink(),
                        post?.photo?.photoURL != null
                            ? context.sh
                            : const SizedBox.shrink(),
                        SizedBox(
                          height: context.imageSizeSmall.height,
                          // heuristic, trying to match screen size
                          // TODO: fix this
                          width: (context.blockSize.width -
                                  context.imageSizeSmall.width -
                                  context.sd.width! -
                                  2.0) *
                              (post?.photo?.photoURL != null ? 0.7 : 0.55),
                          child: Text(
                            // some posts dont have descriptions
                            post?.title ?? "",
                            style: context.m,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // TODO: move this to ProfileIcon widget
                        ProfileIcon(
                          eid: entity?.eid,
                          plid: platform?.plid,
                          radius: context.iconSizeStandard / 2,
                        ),
                      ],
                    ),
            ),
          );
  }
}
