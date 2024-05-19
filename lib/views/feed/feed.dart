// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/logo.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zback_button.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/story.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:political_think/common/services/functions.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/common/services/auth.dart';
import 'package:political_think/views/feed/feed_settings.dart';
import 'package:political_think/views/post/post_builder.dart';
import 'package:political_think/views/post/post_item_view.dart';
import 'package:political_think/views/story/story_item_view.dart';

class Feed extends ConsumerStatefulWidget {
  const Feed({
    super.key,
  });

  static const location = "/feed";

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FeedState();
}

class _FeedState extends ConsumerState<Feed> {
  PagingController<int, Story>? _pagingController;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ZUser?> userRef = ref.selfUserWatch();
    ZUser? user = userRef.value;
    return ZScaffold(
      appBar: ZAppBar(
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              Functions.instance().scrapeX();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.showModal(FeedSettings(onFilterChange: () {
                _pagingController?.refresh();
              }));
            },
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.plus),
            color: context.primaryColor,
            onPressed: () {
              context.showFullScreenModal(const PostBuilder());
            },
          ),
        ],
      ),
      body: userRef.isLoading
          ? const Loading()
          : Center(
              child: RiverPagedBuilder<int, Story>(
                pullToRefresh: true,
                firstPageKey: 0,
                provider: storiesProvider(user?.settings),
                itemBuilder: (context, item, index) {
                  return Column(
                    children: [
                      Visibility(
                        visible: index != 0,
                        child: const ZDivider(),
                      ),
                      Container(
                        width: context.blockSize.width,
                        margin:
                            context.blockMargin.copyWith(left: 0.0, right: 0.0),
                        padding: context.blockPadding
                            .copyWith(left: 0.0, right: 0.0),
                        child: StoryItemView(sid: item.sid),
                      ),
                    ],
                  );
                },
                newPageProgressIndicatorBuilder: (context, controller) {
                  return const Loading(type: LoadingType.standard);
                },
                firstPageProgressIndicatorBuilder: (context, controller) {
                  return const Loading(type: LoadingType.large);
                },
                pagedBuilder: (controller, builder) {
                  _pagingController = controller;
                  return PagedListView(
                    pagingController: controller,
                    builderDelegate: builder,
                  );
                },
              ),
            ),
    );
  }
}
