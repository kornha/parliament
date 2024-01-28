import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/credibility_component.dart';
import 'package:political_think/common/components/interactive/credibility_slider.dart';
import 'package:political_think/common/components/interactive/political_position_joystick.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/services/database.dart';

class PostCredibility extends ConsumerStatefulWidget {
  final Post post;
  final double height;
  final double width;
  const PostCredibility({
    super.key,
    required this.height,
    required this.width,
    required this.post,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostCredibilityViewState();
}

class _PostCredibilityViewState extends ConsumerState<PostCredibility> {
  Vote? _localVote;

  @override
  Widget build(BuildContext context) {
    Vote? vote;
    vote = ref
        .voteWatch(
          widget.post.pid,
          ref.user().uid,
          VoteType.credibility,
        )
        .value;
    // locally set state while waiting for remote
    // unsets on error
    if (vote != null &&
        _localVote != null &&
        vote.credibility != null &&
        _localVote!.credibility != null &&
        vote.createdAt.millisecondsSinceEpoch >=
            _localVote!.createdAt.millisecondsSinceEpoch) {
      _localVote = null;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CredibilitySlider(
          selectedCredibility: _localVote?.credibility ?? vote?.credibility,
          credibility2: widget.post.userCredibility,
          credibility3: widget.post.aiCredibility,
          width: widget.width,
          height: widget.height,
          onCredbilitySelected: (cred) {
            Vote v = Vote(
              uid: ref.user().uid,
              pid: widget.post.pid,
              createdAt: Timestamp.now(),
              type: VoteType.credibility,
              credibility: cred,
            );
            Database.instance()
                .vote(widget.post.pid, v, VoteType.credibility)
                .onError((error, stackTrace) {
              setState(() {
                _localVote = null;
                // TODO: toast
              });
            });

            setState(() {
              _localVote = v;
            });
          },
        ),
      ],
    );
  }
}
