import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/interactive/political_position_joystick.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/views/bias/bias_view.dart';
import 'package:political_think/views/credibility/vote_view.dart';

class BiasWidget extends ConsumerStatefulWidget {
  final Post post;
  final double radius;
  final bool showPositionName;
  final bool showPositionAngle;
  final bool showModalOnPress;

  const BiasWidget({
    super.key,
    required this.radius,
    required this.post,
    this.showPositionName = false,
    this.showPositionAngle = false,
    this.showModalOnPress = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostBiasViewState();
}

class _PostBiasViewState extends ConsumerState<BiasWidget> {
  Vote? _localVote;

  @override
  Widget build(BuildContext context) {
    Vote? vote;
    vote = ref
        .voteWatch(
          widget.post.pid,
          ref.user().uid,
          VoteType.bias,
        )
        .value;
    // locally set state while waiting for remote
    // unsets on error
    if (vote != null &&
        _localVote != null &&
        vote.bias?.position != null &&
        _localVote!.bias?.position != null &&
        vote.createdAt.millisecondsSinceEpoch >=
            _localVote!.createdAt.millisecondsSinceEpoch) {
      _localVote = null;
    }
    return GestureDetector(
      // the ontap does not intercept the joystick
      onTap: widget.showModalOnPress
          ? () {
              context.showModal(BiasView(pid: widget.post.pid));
            }
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              widget.post.aiBias == null
                  ? LoadingPoliticalPositionAnimation(
                      size: widget.radius * 2,
                      rings: 1,
                      give: 0.2,
                    )
                  : PoliticalComponent(
                      radius: widget.radius,
                      rings: 1,
                      position: widget.post.aiBias?.position,
                      give: 0.2,
                      showUnselected: false,
                    ),
              PoliticalComponent(
                radius: widget.radius * 5.0 / 6.0,
                rings: 1,
                position: widget.post.userBias?.position,
                give: 0.195,
                showUnselected: false,
              ),
              PoliticalPositionJoystick(
                selectedPosition:
                    _localVote?.bias?.position ?? vote?.bias?.position,
                radius: widget.radius * 2.0 / 3.0,
                give: 0.19,
                rings: 1,
                showStick: false,
                onPositionSelected: (pos) {
                  Vote v = Vote(
                    uid: ref.user().uid,
                    pid: widget.post.pid,
                    createdAt: Timestamp.now(),
                    type: VoteType.bias,
                    bias: Bias(position: pos),
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
                    type: VoteType.bias,
                  ));
                },
              ),
            ],
          ),
          !widget.showPositionAngle && !widget.showPositionName ||
                  widget.post.userBias == null
              ? const SizedBox.shrink()
              : SizedBox(
                  width: widget.radius * 2.0,
                  child: Text(
                    widget.showPositionAngle
                        ? "${widget.post.aiBias!.position.angle.round()}°"
                        : widget.post.userBias!.position.name,
                    style: widget.radius >= context.iconSizeXL
                        ? context.mb
                        : context.sb,
                    textAlign: TextAlign.center,
                  ),
                ),
        ],
      ),
    );
  }
}
