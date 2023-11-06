import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/position.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/services/functions.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/common/zrouter.dart';
import 'package:political_think/views/post/post_room.dart';
import 'package:shimmer/shimmer.dart';

class PostItem extends ConsumerStatefulWidget {
  const PostItem({
    super.key,
    required this.pid,
    this.showDebateButtons = false,
  });

  final String pid;
  final bool showDebateButtons;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostItem> {
  @override
  Widget build(BuildContext context) {
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;
    return postRef.isLoading
        ? const Loading()
        : Container(
            margin: context.blockMargin,
            padding: context.blockPadding,
            child: Column(
              children: [
                Text(post?.title ?? ""),
                context.sf,
                ZImage(imageUrl: post?.imageUrl ?? ""),
                context.sf,
                Text(post?.description ?? ""),
                Visibility(
                    visible: widget.showDebateButtons, child: context.sf),
                Visibility(
                  visible: widget.showDebateButtons,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ZTextButton(
                        backgroundColor: Palette.blue,
                        child: const Icon(
                          Icons.join_left,
                          color: Palette.white,
                        ),
                        onPressed: () =>
                            goToRoom(context, post!, Quadrant.LEFT),
                      ),
                      ZTextButton(
                        backgroundColor: Palette.red,
                        child: const Icon(
                          Icons.join_right,
                          color: Palette.white,
                        ),
                        onPressed: () =>
                            goToRoom(context, post!, Quadrant.RIGHT),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  goToRoom(BuildContext context, Post post, Quadrant pos) {
    Functions.instance().joinRoom(post.pid, position: pos);
    context.push("${PostRoom.location}/${post.pid}");
  }
}
