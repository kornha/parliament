import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/interactive/confidence_slider.dart';
import 'package:political_think/common/components/interactive/political_position_joystick.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/components/ztextfield.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/vote.dart';
import 'package:political_think/common/services/database.dart';

class VoteView extends ConsumerStatefulWidget {
  // final Vote vote;
  final String pid;
  final String uid;
  final VoteType type;

  const VoteView({
    super.key,
    required this.pid,
    required this.uid,
    required this.type,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _VoteViewState();
}

class _VoteViewState extends ConsumerState<VoteView> {
  final TextEditingController _controller = TextEditingController(text: '');
  Vote? _localVote;
  bool _isButtonEnabled = false;
  // ignore: prefer_typing_uninitialized_variables
  var onData;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // we only use inputted vote to fetch value
    // from there is stream
    var voteRef = ref.voteWatch(
      widget.pid,
      widget.uid,
      widget.type,
    );

    // sets the data initially
    // need to check if onData is null otherwise
    // it will execute every build
    onData ??= voteRef.whenData((vote) {
      _controller.text = vote?.reason ?? '';
    });

    //
    var isError = voteRef.hasError || voteRef.value == null;
    var isLoading = voteRef.isLoading;
    //
    Vote? svote = voteRef.value;
    //
    if (svote?.createdAt != null &&
        _localVote?.createdAt != null &&
        svote!.createdAt.millisecondsSinceEpoch >=
            _localVote!.createdAt.millisecondsSinceEpoch) {
      _localVote = null;
    }
    //
    Vote? vote = _localVote ?? svote;
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
                    const Text("Your rating"),
                    context.sh,
                    Text(
                        vote!.type == VoteType.bias
                            ? vote.bias!.name
                            : vote.confidence!.name,
                        style: context.h1,
                        textAlign: TextAlign.start),
                    context.sf,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        vote.type == VoteType.bias
                            ? PoliticalPositionJoystick(
                                selectedPosition: vote.bias,
                                radius: context.iconSizeXL / 2,
                                onPositionSelected: (pos) {
                                  Vote v = Vote(
                                    uid: ref.user().uid,
                                    pid: vote.pid,
                                    reason: vote.reason,
                                    createdAt: Timestamp.now(),
                                    type: VoteType.bias,
                                    bias: pos,
                                  );
                                  Database.instance()
                                      .vote(v)
                                      .onError((error, stackTrace) {
                                    context.showToast("Could not save vote.",
                                        isError: true);
                                  });
                                  setState(() {
                                    _localVote = v;
                                  });
                                },
                              )
                            : ConfidenceSlider(
                                selectedConfidence: vote.confidence,
                                width: context.iconSizeXL,
                                height: context.iconSizeXL,
                                onConfidenceSelected: (cred) {
                                  Vote v = Vote(
                                    uid: ref.user().uid,
                                    pid: vote.pid,
                                    reason: vote.reason,
                                    createdAt: Timestamp.now(),
                                    type: VoteType.confidence,
                                    confidence: cred,
                                  );
                                  Database.instance()
                                      .vote(v)
                                      .onError((error, stackTrace) {
                                    context.showToast("Could not save vote.",
                                        isError: true);
                                  });
                                  setState(() {
                                    _localVote = v;
                                  });
                                },
                              ),
                        context.sf,
                        Expanded(
                          child: ZTextfield(
                            hintText: "Why?",
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            controller: _controller,
                            maxLines: 25,
                            minLines: 1,
                            cursorColor: vote.type == VoteType.bias
                                ? vote.bias!.color
                                : vote.confidence!.color,
                            onChanged: (text) {
                              setState(() {
                                _isButtonEnabled =
                                    text.isNotEmpty && text != vote.reason;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    context.sf,
                    ZTextButton(
                      type: ZButtonTypes.wide,
                      onPressed: !_isButtonEnabled
                          ? null
                          : () {
                              Vote v = Vote(
                                uid: ref.user().uid,
                                pid: vote.pid,
                                reason: _controller.text,
                                createdAt: Timestamp.now(),
                                type: vote.type,
                                bias: vote.bias,
                                confidence: vote.confidence,
                              );
                              Database.instance()
                                  .vote(v)
                                  .onError((error, stackTrace) {
                                context.showToast("Could not save rating.",
                                    isError: true);
                                setState(() {
                                  _localVote = null;
                                });
                              });
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _isButtonEnabled = false;
                                _localVote = v;
                              });
                            },
                      // backgroundColor: vote.type == VoteType.bias
                      //     ? vote.bias!.color
                      //     : vote.confidence!.color,
                      // foregroundColor: vote.type == VoteType.bias
                      //     ? vote.bias!.onColor
                      //     : vote.confidence!.color,
                      child: const Text("Save"),
                    ),
                  ],
                ),
    );
  }
}
