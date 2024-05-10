import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:political_think/views/post/post_view_buttons.dart';

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

    AsyncValue<Entity?>? entityRef;
    if (post?.eid != null) {
      entityRef = ref.entityWatch(post!.eid!);
    }
    var entity = entityRef?.value;

    return postRef.isLoading
        ? Loading(
            type: widget.isSubView ? LoadingType.postSmall : LoadingType.post)
        : GestureDetector(
            onTap: () => context.go("${PostView.location}/${post?.pid}"),
            child: !widget.isSubView
                ? Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Visibility(
                                visible: entity?.photoURL != null,
                                child: ProfileIcon(url: entity?.photoURL),
                              ),
                              Icon(
                                post?.sourceType.icon,
                                size: context.iconSizeSmall,
                                color: context.secondaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      context.sh,
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
                      storyImportance > 4 && post?.photoURL != null
                          ? ZImage(photoURL: post?.photoURL ?? "")
                          : const SizedBox.shrink(),
                      Visibility(
                          visible: post?.description != null &&
                              (post!.description?.isNotEmpty ?? false),
                          child: context.sf),
                      Visibility(
                          visible: post?.description != null &&
                              (post!.description?.isNotEmpty ?? false),
                          child:
                              Text(post?.description ?? "", style: context.m)),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      post?.photoURL != null
                          ? ZImage(
                              photoURL: post?.photoURL ?? "",
                              imageSize: ZImageSize.small,
                            )
                          : const SizedBox.shrink(),
                      post?.photoURL != null
                          ? context.sh
                          : const SizedBox.shrink(),
                      SizedBox(
                        height: context.imageSizeSmall.height,
                        // heuristic, trying to match screen size
                        width: (context.blockSize.width -
                                context.imageSizeSmall.width -
                                context.sd.width! -
                                2.0) *
                            (post?.photoURL != null ? 1 : 0.7),
                        child: Text(
                          // some posts dont have descriptions
                          post?.description ?? post?.title ?? "",
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
