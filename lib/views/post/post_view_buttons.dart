import 'package:flutter/material.dart';
import 'package:political_think/common/components/comment_widget.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/confidence/confidence_widget.dart';

// DEPRECATED: This widget is no longer used in the app

class PostViewButtons extends StatelessWidget {
  final Post post;
  final Story? story;
  final bool showMap;
  final bool showConfidence;
  final bool showBias;
  final bool showComments;
  //final bool showComments;

  const PostViewButtons({
    super.key,
    required this.post,
    this.showMap = true,
    this.showConfidence = true,
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
        // TODO: FIX THIS TO USE NEW LOCATION
        // Visibility(
        //   visible: showMap,
        //   child: Padding(
        //       padding: EdgeInsets.symmetric(
        //           horizontal:
        //               (context.iconSizeXL - context.iconSizeLarge) / 2.0),
        //       child: LocationMap(
        //         // need to update
        //         locations: const [],
        //         width: context.iconSizeLarge,
        //         height: context.iconSizeLarge,
        //       )),
        // ),
        Visibility(
            visible: showComments,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal:
                      (context.iconSizeXL - context.iconSizeLarge) / 2.0),
              child: CommentWidget(
                comments: post.messageCount,
                position: post.debateBias,
              ),
            )),
        // padding to space evently with post bias
        Visibility(
          visible: showConfidence,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: (context.iconSizeXL - context.iconSizeLarge) / 2.0),
            // need stid or eid! won't compile!
            child: ConfidenceWidget(
              height: context.iconSizeLarge,
              width: context.iconSizeLarge,
            ),
          ),
        ),
        Visibility(
          visible: showBias,
          // need stid or eid! won't compile!
          child: PoliticalPositionWidget(
            radius: context.iconSizeXL / 2,
          ),
        ),
      ],
    );
  }
}
