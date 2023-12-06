import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/services/functions.dart';
import 'package:political_think/common/util/swipe_area.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/common/zrouter.dart';
import 'package:political_think/views/post/post_room.dart';
import 'package:shimmer/shimmer.dart';

class PostView extends ConsumerStatefulWidget {
  const PostView({
    super.key,
    required this.pid,
    this.showDebateButtons = false,
  });

  final String pid;
  final bool showDebateButtons;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostView> {
  @override
  Widget build(BuildContext context) {
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;
    return postRef.isLoading
        ? const Loading()
        : Container(
            margin: context.blockMargin,
            padding: context.blockPadding,
            // constraints: BoxConstraints(
            //   maxWidth: context.imageSize.width,
            //   maxHeight: context.imageSize.height * 2.2,
            // ),
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
                  child: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const PoliticalComponent(),
                        DebateJoystick(
                          onPositionSelected: (pos) {},
                        ),
                        const PoliticalComponent(),

                        // ZTextButton(
                        //   backgroundColor: Palette.blue,
                        //   child: const Icon(
                        //     Icons.join_left,
                        //     color: Palette.white,
                        //   ),
                        //   onPressed: () =>
                        //       goToRoom(context, post!, Quadrant.left),
                        // ),
                        // ZTextButton(
                        //   backgroundColor: Palette.red,
                        //   child: const Icon(
                        //     Icons.join_right,
                        //     color: Palette.white,
                        //   ),
                        //   onPressed: () =>
                        //       goToRoom(context, post!, Quadrant.right),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  _goToRoom(BuildContext context, Post post, Quadrant pos) {
    Functions.instance().joinRoom(post.pid, position: pos);
    context.push("${PostRoom.location}/${post.pid}");
  }
}

class DebateJoystick extends StatefulWidget {
  const DebateJoystick({
    super.key,
    this.onPositionSelected,
  });

  final ValueChanged<PoliticalPosition>? onPositionSelected;

  @override
  State<DebateJoystick> createState() => _DebateJoystickState();
}

class _DebateJoystickState extends State<DebateJoystick> {
  PoliticalPosition? _position;
  @override
  Widget build(BuildContext context) {
    return Joystick(
      stick: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.surfaceColor.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.surfaceColor,
              context.backgroundColor,
            ],
          ),
        ),
      ),
      base: PoliticalComponent(position: _position),
      listener: (StickDragDetails details) {
        setState(() {
          _position = PoliticalPosition.fromCoordinate(details.x, details.y);
        });
        //widget.onPositionSelected?.call(_position!);
      },
    );
  }
}
