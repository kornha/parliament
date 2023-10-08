import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/position.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:political_think/views/post/post_builder.dart';
import 'package:political_think/views/post/post_item.dart';
import 'package:shimmer/shimmer.dart';

class PostView extends ConsumerStatefulWidget {
  const PostView({
    super.key,
    this.pid,
    this.position,
  });

  final String? pid;
  final PoliticalPosition? position;

  static const fullLocation = '/post/:pid/:position';
  static const location = '/post';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostView> {
  final List<Message> messageList = [
    Message(
      id: '1',
      message: "Hi",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '2',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '3',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '4',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '5',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '6',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '7',
      message: "assssaasdfas",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '8',
      message: "Hi",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '9',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '2',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '2',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '2',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '2',
      message: "Hello",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
    Message(
      id: '2',
      message: "assssaasdfas",
      createdAt: DateTime.now(),
      sendBy: "H96zDI88u6wUtuLSnQU98Wb2k1Ds",
    ),
  ];

  late final chatController = ChatController(
    initialMessageList: messageList,
    scrollController: ScrollController(),
    chatUsers: [ChatUser(id: 'H96zDI88u6wUtuLSnQU98Wb2k1Ds', name: 'Simform')],
  );

  @override
  Widget build(BuildContext context) {
    var postRef = ref.postWatch(widget.pid);
    var value = postRef.value;
    return ZScaffold(
      appBar: ZAppBar(leading: const ZBackButton()),
      body: postRef.isLoading
          ? const Loading()
          : !postRef.hasValue
              ? const ZError()
              : ChatView(
                  chatController: chatController,
                  currentUser: chatController.chatUsers.first,
                  chatViewState: ChatViewState.hasMessages,
                  chatBubbleConfig: ChatBubbleConfiguration(),
                  messageConfig: MessageConfiguration(),
                  chatBackgroundConfig: ChatBackgroundConfiguration(
                    backgroundColor: context.backgroundColor,
                  ),
                ),
    );
  }
}
