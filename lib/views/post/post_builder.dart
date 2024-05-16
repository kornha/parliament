import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/modal_container.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/services/functions.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/post/post_item_view.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:uuid/uuid.dart';

class PostBuilder extends ConsumerStatefulWidget {
  const PostBuilder({super.key, this.url});
  final String? url;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostBuilderState();
}

class _PostBuilderState extends ConsumerState<PostBuilder> {
  String? _pid;
  bool _loading = false;
  bool _isError = false;
  String _errorText = "Can't unfurl";

  @override
  void initState() {
    super.initState();
    // todo: localstate
    // Database.instance().getFirstPostInDraft(ref.user().uid).then((post) {
    //   // Check if the widget is still mounted
    //   if (mounted) {
    //     setState(() {
    //       _pid = post?.pid;
    //       _loading = false;
    //     });
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<Post?>? postRef;
    if (_pid != null) {
      postRef = ref.postWatch(_pid!);
    }
    if (postRef != null && postRef.isLoading) {
      _loading = true;
    } else if (postRef != null && !postRef.hasValue) {
      _isError = false;
      _errorText = "Can't unfurl";
    }

    Post? post = postRef?.value;

    // we check title because the post can be created without a title while its scraping
    if (postRef != null &&
        postRef.hasValue &&
        post?.status == PostStatus.draft) {
      return ModalContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PostItemView(pid: _pid!, showPostButtons: false),
            context.sf,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ZTextButton(
                  onPressed: () {
                    Database.instance().deletePost(postRef!.value!);
                    setState(() {
                      _pid = null;
                      _loading = false;
                    });
                  },
                  foregroundColor: context.primaryColor,
                  backgroundColor: context.backgroundColor,
                  child: const Text("Discard"),
                ),
                context.sf,
                ZTextButton(
                  onPressed: () {
                    Post? p = postRef!.value;
                    if (p == null) {
                      context.pop();
                    } else {
                      Database.instance().updatePost(p.pid, {
                        "status": PostStatus.published.name,
                        "updatedAt": Timestamp.now().millisecondsSinceEpoch,
                      });
                      context.pop();
                      context.go("${PostView.location}/${_pid!}");
                    }
                  },
                  backgroundColor: context.secondaryColor,
                  foregroundColor: context.onSecondaryColor,
                  child: const Text("Generate"),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ModalContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            flex: 2,
            child: PasteArea(
              loading: _loading,
              error: _isError,
              errorText: _errorText,
              onPaste: _loading
                  ? null
                  : () async {
                      ClipboardData? clipboardData =
                          await Clipboard.getData(Clipboard.kTextPlain);
                      String? url = clipboardData!.text!;
                      Uri? uri = Uri.tryParse(url);
                      if (uri == null ||
                          uri.scheme != "http" && uri.scheme != "https") {
                        setState(() {
                          _isError = true;
                          _errorText = "No url on clipboard";
                        });
                        return;
                      }
                      setState(() {
                        _loading = true;
                      });
                      String? pid =
                          await Functions.instance().pasteLink(uri.toString());
                      if (pid == null) {
                        setState(() {
                          _isError = true;
                          _errorText = "Can't unfurl";
                          _loading = false;
                        });
                        return;
                      }
                      setState(() {
                        _pid = pid;
                      });
                      // we don't need to set loading to false because the postRef will
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class PasteArea extends StatelessWidget {
  const PasteArea({
    super.key,
    this.onPaste,
    this.error = false,
    this.loading = false,
    this.errorText = "There's an error",
  });

  final Function()? onPaste;
  final bool error;
  final bool loading;
  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: context.screenBlock.width,
        height: context.screenBlock.height,
        decoration: BoxDecoration(
          borderRadius: BRadius.steep,
          border: Border.fromBorderSide(BorderSide(
            color: context.primaryColorWithOpacity,
          )),
        ),
        child: ZTextButton(
          type: ZButtonTypes.area,
          backgroundColor: context.backgroundColor,
          foregroundColor: context.primaryColor,
          onPressed: onPaste,
          child: loading
              ? const Loading(type: LoadingType.large)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // TODO: NEED A ROW TO FILL SCREEN
                    const Row(),
                    error
                        ? Column(
                            children: [
                              Text(errorText,
                                  style: context.h3
                                      .copyWith(color: context.errorColor)),
                              context.sq,
                              Text("Please try again", style: context.l),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              context.sh,
                              Text("Paste a link here", style: context.h2),
                              context.sq,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(FontAwesomeIcons.solidNewspaper),
                                  context.sq,
                                  Text(" Article", style: context.l),
                                ],
                              ),
                              context.sh,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(FontAwesomeIcons.xTwitter),
                                  context.sq,
                                  Text(" X/Twitter", style: context.l),
                                ],
                              ),
                              context.sd,
                              const Text("Coming soon"),
                              context.sq,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(FontAwesomeIcons.tiktok),
                                  context.sq,
                                  const Icon(FontAwesomeIcons.reddit),
                                  context.sq,
                                  const Icon(FontAwesomeIcons.instagram),
                                  context.sq,
                                  const Icon(FontAwesomeIcons.facebook),
                                  context.sq,
                                  const Icon(FontAwesomeIcons.youtube),
                                ],
                              ),
                              context.sq,
                            ],
                          ),
                  ],
                ),
        ),
      ),
    );
  }
}
