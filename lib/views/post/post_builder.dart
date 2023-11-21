import 'package:any_link_preview/any_link_preview.dart';
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
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/views/post/post_item.dart';
import 'package:super_clipboard/super_clipboard.dart';
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
  Widget? header = const Icon(FontAwesomeIcons.paste);
  @override
  void initState() {
    super.initState();
    Database.instance().getFirstPostInDraft(ref.user().uid).then((post) {
      setState(() {
        _pid = post?.pid;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ModalContainer(child: Loading());
    // No draft
    if (_pid == null) {
      return ModalContainer(
        child: PasteArea(
          header: header,
          onPaste: () async {
            setState(() {
              _loading = true;
            });
            final reader = await ClipboardReader.readClipboard();
            final url = await reader.readValue(Formats.uri);

            // Metadata? metadata = url == null
            //     ? null
            //     : await AnyLinkPreview.getMetadata(link: url.uri.toString());

            final OgpData? metadata = url == null
                ? null
                : await OgpDataExtract.execute(url.uri.toString());
            if (metadata == null) {
              setState(() {
                _loading = false;
                header = ZError(size: IconTheme.of(context).size!);
              });
            } else {
              Post p = Post(
                pid: const Uuid().v4(),
                creator: ref.selfUserRead().value!.uid,
                status: PostStatus.draft,
                createdAt: Timestamp.now(),
                updatedAt: Timestamp.now(),
                title: metadata.title,
                description: metadata.description,
                imageUrl: metadata.image,
                url: metadata.url,
              );
              Database.instance().createPost(p);
              setState(() {
                _loading = false;
                _pid = p.pid;
              });
            }
          },
        ),
      );
    }
    // already draft
    var postRef = ref.postWatch(_pid!);
    if (postRef.isLoading) return const ModalContainer(child: Loading());
    if (!postRef.hasValue) return const ModalContainer(child: ZError());
    return ModalContainer(
      child: Column(
        children: [
          PostItem(pid: _pid!, showDebateButtons: false),
          context.sf,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ZTextButton(
                onPressed: () {
                  Database.instance().deletePost(postRef.value!);
                  setState(() {
                    _pid = null;
                  });
                },
                foregroundColor: context.errorColor,
                child: Text("Discard"),
              ),
              context.sf,
              ZTextButton(
                onPressed: () {
                  Post p = postRef.value!;
                  p.status = PostStatus.published;
                  Database.instance().updatePost(p);
                  context.pop();
                },
                foregroundColor: context.secondaryColor,
                child: Text("Post"),
              ),
              context.sd,
            ],
          ),
        ],
      ),
    );
  }
}

class PasteArea extends StatelessWidget {
  const PasteArea({super.key, required this.onPaste, this.header, this.footer});

  final Function() onPaste;
  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPaste,
      child: SizedBox(
        width: context.screenSize.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            header ?? const Icon(FontAwesomeIcons.paste),
            context.sf,
            footer ?? const Text("Paste URL"),
          ],
        ),
      ),
    );
  }
}
