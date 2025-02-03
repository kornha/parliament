import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/ztheme.dart';

import 'package:political_think/views/post/post_item_view.dart';
import 'package:political_think/views/post/room_clock.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:uuid/uuid.dart';
import '../../common/chat/chat_types/flutter_chat_types.dart' as ct;
import '../../common/chat/flutter_chat_ui.dart';

class PostView extends ConsumerStatefulWidget {
  const PostView({
    super.key,
    required this.pid,
  });

  final String pid;

  static const location = '/post';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostView> {
  final AutoScrollController _autoScrollController = AutoScrollController();
  // final ScrollController _scrollController = ScrollController();

  //List<chat.User> _users = [];
  List<ct.Message> _messages = [];
  final List<ct.Message> _localMessages = [];
  bool _isLastMessage = false;
  final int _limit = Constants.MESSAGE_FETCH_LIMIT;
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    //
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;
    //
    var roomRef = ref.activeRoomWatch(widget.pid);
    var room = roomRef.value;
    //
    var messagesRef = room == null ? null : ref.messagesWatch(room.rid, _limit);
    var messages = messagesRef?.value;
    // I tried directly comparing messages but it would sometimes fail
    // so I'm comparing the last message id instead
    if (_messages.isNotEmpty && _messages.last.id == messages?.last.id) {
      _isLastMessage = true;
    }
    if (messages != null) {
      _messages = messages;
      _isLoaded = true;
    }
    //
    var isError = postRef.hasError ||
        roomRef.hasError ||
        (messagesRef?.hasError ?? false);
    //
    var isLoading = !_isLoaded &&
        (postRef.isLoading ||
            roomRef.isLoading ||
            // this is because we assume there's always an active room!
            room == null ||
            (messagesRef?.isLoading ?? false));
    //
    return ZScaffold(
        appBar: ZAppBar(showBackButton: true),
        ignoreScrollView: true,
        body: isLoading
            ? const Loading()
            : isError
                ? const ZError()
                : Column(
                    children: [
                      PostItemView(pid: post!.pid, gestureDetection: false),
                    ],
                  )
        // : Chat(
        //     theme: context.isDarkMode
        //         ? ZTheme.darkChatTheme
        //         : ZTheme.lightChatTheme,
        //     scrollController: _autoScrollController,
        //     pinnedMessageHeader: Container(
        //       // margin: context.blockMargin,
        //       // padding: context.blockPaddingExtra,
        //       decoration: BoxDecoration(
        //         color: context.backgroundColor,
        //         borderRadius: BRadius.standard,
        //       ),
        //       child: PostItemView(pid: post!.pid),
        //     ),
        //     pinnedMessageFooter:
        //         _messages.isNotEmpty ? RoomClock(room: room!) : null,
        //     isLastPage: _isLastMessage,
        //     messages: _messages,
        //     messageExpiryTime: room!.clock?.end?.millisecondsSinceEpoch,
        //     onSendPressed: (pt) {
        //       final msg = ct.TextMessage(
        //         roomId: room.rid,
        //         author: ct.User(
        //             id: ref.user().uid), // ref.user().toChatUser(),
        //         id: const Uuid().v4(),
        //         text: pt.text,
        //         createdAt: Timestamp.now().millisecondsSinceEpoch,
        //         position: room.getUserPosition(ref.user().uid),
        //         status: ct.Status.sending,
        //       );
        //       Database.instance().createMessage(
        //         room.rid,
        //         msg.copyWith(status: ct.Status.sent),
        //       );
        //       setState(() {
        //         _localMessages.add(msg);
        //       });
        //     },
        //     onEndReached: () async {
        //       setState(() {
        //         _limit += Constants.MESSAGE_FETCH_LIMIT;
        //       });
        //     },
        //     user: ref.user().toChatUser(),
        //   ),
        );
  }

  List<ct.Message> get _combinedMessages {
    var ret = [..._messages];
    var loc = [..._localMessages];
    for (int i = 0; i < min(loc.length, 10); i++) {
      var msg = loc[i];
      for (int j = 0; j < ret.length; j++) {
        if (msg.id == ret[j].id) {
          _localMessages.removeWhere((lm) => lm.id == msg.id);
          break;
        }
        if (msg.createdAt! > ret[j].createdAt!) {
          ret.insert(j, msg);
          break;
        }
      }
    }
    return ret;
  }
}
