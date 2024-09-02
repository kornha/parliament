import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/Confidence_component.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/views/confidence/confidence_widget.dart';

class ConfidenceView extends ConsumerStatefulWidget {
  final String pid;

  const ConfidenceView({
    super.key,
    required this.pid,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ConfidenceViewViewState();
}

class _ConfidenceViewViewState extends ConsumerState<ConfidenceView> {
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
            VoteType.confidence,
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
                    Text(post!.primaryConfidence?.name ?? "Confidence Score",
                        style: context.h1, textAlign: TextAlign.start),
                    context.sf,
                    Row(
                      children: [
                        // need stid or eid! won'tt compile!
                        ConfidenceWidget(
                          width: context.iconSizeXL,
                          height: context.iconSizeXL,
                          // post: post,
                          // showValue: false,
                          // showModalOnPress: false,
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
                      post.aiConfidence?.value,
                      post.aiConfidence?.name,
                    ),
                    _infoRow(
                      context,
                      SizedBox(
                        width: context.iconSizeStandard +
                            context.blockPadding
                                .horizontal, // TODO: HACK FOR UI CHANGE TO GRID
                        child: Text(
                            post.voteCountConfidence < 1000
                                ? post.voteCountConfidence.toString()
                                : "${(post.voteCountConfidence / 1000).toStringAsFixed(1)}k",
                            style: context.am.copyWith(
                                color: post.userConfidence?.color ??
                                    context.primaryColor),
                            textAlign: TextAlign.center),
                      ),
                      post.userConfidence?.value,
                      post.userConfidence?.name,
                    ),
                    _infoRow(
                      context,
                      Padding(
                        padding:
                            context.blockPadding.copyWith(top: 0, bottom: 0),
                        child: ProfileIcon(
                            watch: false, radius: context.iconSizeStandard / 2),
                      ), // TODO: HACK FOR UI CHANGE TO GRID
                      vote?.confidence?.value,
                      vote?.confidence?.name,
                    ),
                  ],
                ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    Widget first,
    double? second,
    String? third,
  ) {
    return Container(
      //margin: context.blockMargin.copyWith(top: 0, bottom: 0),
      padding: context.blockPadding,
      child: Row(
        children: [
          first,
          context.sd,
          ConfidenceComponent(
            confidence: Confidence(value: second ?? 0.0),
            width: context.iconSizeStandard,
            height: context.iconSizeStandard,
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
