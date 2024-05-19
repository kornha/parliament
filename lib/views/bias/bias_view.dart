import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/views/bias/bias_widget.dart';

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
    //
    Vote? vote;
    if (post != null) {
      vote = ref
          .voteWatch(
            post.pid,
            ref.user().uid,
            VoteType.bias,
          )
          .value;
    }
    //
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
                    Text("${post!.aiBias?.position.name ?? "Political"} Bias",
                        style: context.h1, textAlign: TextAlign.start),
                    context.sf,
                    Row(
                      children: [
                        BiasWidget(
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
                    _infoRow(
                      context,
                      Padding(
                        padding:
                            context.blockPadding.copyWith(top: 0, bottom: 0),
                        child: Logo(size: context.iconSizeStandard),
                      ), // TODO: HACK FOR UI CHANGE TO GRID
                      post.aiBias?.position,
                      post.aiBias?.position.name,
                    ),
                    _infoRow(
                      context,
                      SizedBox(
                        width: context.iconSizeStandard +
                            context.blockPadding
                                .horizontal, // TODO: HACK FOR UI CHANGE TO GRID
                        child: Text(
                            post.voteCountBias < 1000
                                ? post.voteCountBias.toString()
                                : "${(post.voteCountBias / 1000).toStringAsFixed(1)}k",
                            style: context.am.copyWith(
                                color: post.userBias?.position.color ??
                                    context.primaryColor),
                            textAlign: TextAlign.center),
                      ),
                      post.userBias?.position,
                      post.userBias?.position.name,
                    ),
                    _infoRow(
                      context,
                      Padding(
                        padding:
                            context.blockPadding.copyWith(top: 0, bottom: 0),
                        child: ProfileIcon(
                            watch: false, size: context.iconSizeStandard),
                      ), // TODO: HACK FOR UI CHANGE TO GRID
                      vote?.bias?.position,
                      vote?.bias?.position.name,
                    ),
                  ],
                ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    Widget first,
    PoliticalPosition? second,
    String? third,
  ) {
    return Container(
      //margin: context.blockMargin.copyWith(top: 0, bottom: 0),
      padding: context.blockPadding,
      child: Row(
        children: [
          first,
          context.sd,
          PoliticalComponent(
            position: second,
            radius: context.iconSizeSmall,
          ),
          context.sd,
          Expanded(
            child: Text(
              third ?? "",
              style: context.m,
            ),
          ),
        ],
      ),
    );
  }
}
