import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/stats_table.dart';
import 'package:political_think/common/components/zicon_text.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/confidence/confidence_widget.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:url_launcher/url_launcher.dart';

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
            cursor: widget.gestureDetection
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
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
                        Visibility(
                          visible: post != null,
                          child: StatsTable(map: {
                            "Virality": ConfidenceWidget(
                              confidence: post?.virality,
                              viral: true,
                              enabled: false,
                            ),
                            "Replies":
                                Text(Utils.numToReadableString(post?.replies)),
                            "Reposts":
                                Text(Utils.numToReadableString(post?.reposts)),
                            "Likes":
                                Text(Utils.numToReadableString(post?.likes)),
                            "Bookmarks": Text(
                                Utils.numToReadableString(post?.bookmarks)),
                            "Views":
                                Text(Utils.numToReadableString(post?.views)),
                            "Source Created At": Text(Utils.toHumanReadableDate(
                                post?.sourceCreatedAt)),
                            "Source": ZTextButton(
                              onPressed: post?.url == null
                                  ? null
                                  : () {
                                      final Uri url =
                                          Uri.parse(post?.url ?? "");
                                      launchUrl(url);
                                    },
                              child: Text("link",
                                  style: context.mb
                                      .copyWith(color: context.secondaryColor)),
                            ),
                          }),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (post?.photo?.photoURL != null)
                          ZImage(
                            photoURL: post?.photo?.photoURL ?? "",
                            imageSize: ZImageSize.small,
                          ),
                        if (post?.photo?.photoURL != null) context.sh,
                        // Use Expanded to allow the text to take up the remaining space
                        Expanded(
                          child: SizedBox(
                            height: context.imageSizeSmall.height,
                            child: Text(
                              post?.title ?? "",
                              style: context.m,
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
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
