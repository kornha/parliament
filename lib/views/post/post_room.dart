import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/position.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_item.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:uuid/uuid.dart';
import '../../common/chat/chat_types/flutter_chat_types.dart' as ct;
import '../../common/chat/flutter_chat_ui.dart';

class PostRoom extends ConsumerStatefulWidget {
  const PostRoom({
    super.key,
    required this.pid,
  });

  final String pid;

  static const location = '/post';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostRoom> {
  AutoScrollController _scrollController = AutoScrollController();

  //List<chat.User> _users = [];
  MessagesNotifier? mn = null;
  List<ct.Message> _messages = [];
  bool _isLastMessage = false;
  int _limit = Constants.MESSAGE_FETCH_LIMIT;
  bool _isLoaded = false;
  //

  @override
  Widget build(BuildContext context) {
    //
    var postRef = ref.postWatch(widget.pid);
    var post = postRef.value;
    //
    var roomRef = ref.roomWatch(ref.user().uid, widget.pid);
    var room = roomRef.value;
    //
    var messagesRef = room == null ? null : ref.messagesWatch(room.rid, _limit);
    var messages = messagesRef?.value;
    if (_messages.isNotEmpty && _messages.last == messages?.last) {
      _isLastMessage = true;
    }
    if (messages != null) {
      _messages = messages;
      _isLoaded = true;
    }
    //
    var isLoading = !_isLoaded &&
        (postRef.isLoading ||
            roomRef.isLoading ||
            (messagesRef?.isLoading ?? true));
    //
    var isError = postRef.hasError ||
        roomRef.hasError ||
        (messagesRef?.hasError ?? false);
    //
    return ZScaffold(
      appBar: ZAppBar(leading: const ZBackButton()),
      scrollController: _scrollController,
      body: isLoading
          ? const Loading()
          : isError
              ? const ZError()
              : room == null
                  ? const Center(child: Text("Joining a debate..."))
                  : Chat(
                      pinnedMessageHeader: !messagesRef!.isLoading
                          ? PostItem(pid: post!.pid)
                          : const Loading(),
                      isLastPage: _isLastMessage,
                      //TODO: move this
                      theme: DefaultChatTheme(
                        backgroundColor: context.backgroundColor,
                      ),
                      messages: _messages,
                      onSendPressed: (pt) {
                        Database.instance().createMessage(
                          ct.TextMessage(
                            roomId: room.rid,
                            author: ct.User(
                                id: ref.user().uid), // ref.user().toChatUser(),
                            id: const Uuid().v4(),
                            text: pt.text,
                            createdAt: Timestamp.now().millisecondsSinceEpoch,
                            // position: room.getUserPosition(ref.user().uid),
                            status: ct.Status.sending,
                          ),
                        );
                      },
                      onEndReached: () async {
                        setState(() {
                          _limit += Constants.MESSAGE_FETCH_LIMIT;
                        });
                      },
                      user: ref.user().toChatUser(),
                    ),
    );
  }
}
