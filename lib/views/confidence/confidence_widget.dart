import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/interactive/confidence_slider.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/views/confidence/confidence_view.dart';
import 'package:political_think/views/confidence/vote_view.dart';

class ConfidenceWidget extends ConsumerStatefulWidget {
  final Post post;
  final double height;
  final double width;
  final bool showModalOnPress;
  final bool showValue;
  final bool showText;

  const ConfidenceWidget({
    super.key,
    required this.height,
    required this.width,
    required this.post,
    this.showValue = true,
    this.showModalOnPress = false,
    this.showText = true,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostConfidenceViewState();
}

class _PostConfidenceViewState extends ConsumerState<ConfidenceWidget> {
  Vote? _localVote;

  @override
  Widget build(BuildContext context) {
    Vote? vote;
    vote = ref
        .voteWatch(
          widget.post.pid,
          ref.user().uid,
          VoteType.confidence,
        )
        .value;
    // locally set state while waiting for remote
    // unsets on error
    if (vote != null &&
        _localVote != null &&
        vote.confidence != null &&
        _localVote!.confidence != null &&
        vote.createdAt.millisecondsSinceEpoch >=
            _localVote!.createdAt.millisecondsSinceEpoch) {
      _localVote = null;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConfidenceSlider(
              selectedConfidence: _localVote?.confidence ?? vote?.confidence,
              confidence2: widget.post.userConfidence,
              confidence3: widget.post.aiConfidence,
              showNull3AsLoading: true,
              width: widget.width,
              height: widget.height,
              onConfidenceSelected: (cred) {
                Vote v = Vote(
                  uid: ref.user().uid,
                  pid: widget.post.pid,
                  createdAt: Timestamp.now(),
                  type: VoteType.confidence,
                  confidence: cred,
                );
                Database.instance().vote(v).onError((error, stackTrace) {
                  setState(() {
                    _localVote = null;
                    // TODO: toast
                  });
                });

                setState(() {
                  _localVote = v;
                });
                context.showModal(VoteView(
                  pid: widget.post.pid,
                  uid: ref.user().uid,
                  type: VoteType.confidence,
                ));
              },
            ),
          ],
        ),
        Visibility(
          visible: widget.showValue,
          child: Text(
            widget.post.primaryConfidence?.value.toString() ?? "",
            style: widget.width > IconSize.large ? context.h3 : context.l,
            textAlign: TextAlign.center,
          ),
        ),
        Visibility(
          visible: widget.showModalOnPress,
          child: GestureDetector(
            // the ontap does not intercept the joystick
            onTap: widget.showModalOnPress
                ? () {
                    context.showModal(ConfidenceView(pid: widget.post.pid));
                  }
                : null,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
