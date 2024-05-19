import 'package:flutter/material.dart';
import 'package:political_think/common/components/comment_widget.dart';
import 'package:political_think/common/components/location_map.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/views/bias/bias_widget.dart';
import 'package:political_think/views/credibility/credibility_widget.dart';

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
                  horizontal:
                      (context.iconSizeXL - context.iconSizeLarge) / 2.0),
              child: LocationMap(
                locations: post.locations.isNotEmpty
                    ? post.locations
                    : story?.locations ?? [],
                width: context.iconSizeLarge,
                height: context.iconSizeLarge,
              )),
        ),
        Visibility(
            visible: showComments,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal:
                      (context.iconSizeXL - context.iconSizeLarge) / 2.0),
              child: CommentWidget(
                comments: post.messageCount,
                position: post.debateBias?.position,
              ),
            )),
        // padding to space evently with post bias
        Visibility(
          visible: showCredibility,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: (context.iconSizeXL - context.iconSizeLarge) / 2.0),
            child: CredibilityWidget(
              post: post,
              showModalOnPress: true,
              height: context.iconSizeLarge,
              width: context.iconSizeLarge,
            ),
          ),
        ),
        Visibility(
          visible: showBias,
          child: BiasWidget(
            post: post,
            showModalOnPress: true,
            radius: context.iconSizeXL / 2,
          ),
        ),
      ],
    );
  }
}
