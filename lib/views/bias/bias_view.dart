import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/interactive/political_position_joystick.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/views/post/post_bias.dart';

class BiasView extends ConsumerStatefulWidget {
  final String pid;

  const BiasView({
    super.key,
    required this.pid,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BiasViewViewState();
}

class _BiasViewViewState extends ConsumerState<BiasView> {
  @override
  Widget build(BuildContext context) {
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;
    var isError = postRef.hasError || !postRef.hasValue;
    var isLoading = postRef.isLoading;
    return Container(
      margin: context.blockMargin,
      padding: context.blockPadding,
      child: isLoading
          ? const Loading()
          : isError
              ? const ZError()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${post!.userBias?.position.name ?? "Political"} Bias",
                        style: context.h1, textAlign: TextAlign.start),
                    context.sf,
                    Row(
                      children: [
                        PostBias(
                          radius: context.iconSizeXL,
                          post: post,
                          showModalOnPress: false,
                        ),
                        context.sf,
                        Expanded(
                          child: Text(
                            post.aiBias!.reason!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 25, // TODO: Make scrollable!
                          ),
                        ),
                      ],
                    ),
                    context.sf,
                    ZTextButton(
                      child: const Text("Learn More"),
                      onPressed: () {},
                    ),
                  ],
                ),
    );
  }
}
