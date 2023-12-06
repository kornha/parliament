import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/views/post/post_builder.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class Feed extends ConsumerStatefulWidget {
  const Feed({super.key});

  static const location = "/feed";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FeedState();
}

class _FeedState extends ConsumerState<Feed> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<ZUser?> user = ref.selfUserWatch();

    return user.isLoading
        ? const Loading()
        : ZScaffold(
            appBar: ZAppBar(
              actions: [
                IconButton(
                  icon: const Icon(FontAwesomeIcons.plus),
                  color: context.primaryColor,
                  onPressed: () {
                    context.showModal(const PostBuilder());
                  },
                ),
              ],
            ),
            body: Center(
              child: RiverPagedBuilder<int, Post>(
                pullToRefresh: true,
                firstPageKey: 0,
                provider: postsProvider,
                itemBuilder: (context, item, index) {
                  return Column(
                    children: [
                      Visibility(
                        visible: index != 0,
                        child: const ZDivider(),
                      ),
                      PostView(pid: item.pid, showDebateButtons: true),
                    ],
                  );
                },
                pagedBuilder: (controller, builder) => PagedListView(
                  pagingController: controller,
                  builderDelegate: builder,
                ),
              ),
            ),
          );
  }
}
