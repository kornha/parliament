import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/stats_table.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zicon_text.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/Confidence/Confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/post/post_item_view.dart';

class EntityView extends ConsumerStatefulWidget {
  const EntityView({
    super.key,
    required this.eid,
  });

  final String eid;

  static const location = '/entity';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EntityItemViewState();
}

class _EntityItemViewState extends ConsumerState<EntityView> {
  @override
  Widget build(BuildContext context) {
    var entityRef = ref.entityWatch(widget.eid);
    var entity = entityRef.value;

    AsyncValue<List<Post>?> allPostsRef;
    List<Post>? allPosts;

    if (entity?.eid != null) {
      allPostsRef = ref.postsFromEntityWatch(entity!.eid);
      allPosts = allPostsRef.value;
    }

    return ZScaffold(
      appBar: ZAppBar(showBackButton: true),
      body: entityRef.isLoading
          ? const Loading()
          : !entityRef.hasValue
              ? const ZError()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // use url not eid to avoid default routing
                    ProfileIcon(url: entity!.photoURL!),
                    context.sh,
                    Text(
                      entity.handle,
                      style: context.h2b,
                    ),
                    context.sf,
                    Icon(
                      entity.sourceType.icon,
                      size: context.iconSizeStandard,
                      color: context.secondaryColor,
                    ),
                    context.sf,
                    const ZDivider(),
                    context.sh,

                    Visibility(
                        visible: allPosts != null && allPosts.isNotEmpty,
                        child: SizedBox(
                          height: context.blockSizeSmall.height,
                          child: ListView.separated(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: allPosts?.length ?? 0,
                            itemBuilder: (context, index) {
                              var post = allPosts![index];
                              return PostItemView(
                                pid: post.pid,
                                isSubView: true,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const ZDivider(type: DividerType.VERTICAL),
                          ),
                        )),
                    Visibility(
                        visible: allPosts != null && allPosts.isNotEmpty,
                        child: context.sh),
                    Visibility(
                        visible: allPosts != null && allPosts.isNotEmpty,
                        child: const ZDivider()),
                    Visibility(
                        visible: allPosts != null && allPosts.isNotEmpty,
                        child: context.sh),
                    StatsTable(map: {
                      "Confidence": ConfidenceWidget(
                          confidence: entity.confidence, eid: entity.eid),
                      "Bias": PoliticalPositionWidget(
                        position: entity.bias,
                        eid: entity.eid,
                      ),
                      // other stats here
                      "Avg. Replies":
                          Text(Utils.numToReadableString(entity.avgReplies)),
                      "Avg. Reposts":
                          Text(Utils.numToReadableString(entity.avgReposts)),
                      "Avg. Likes":
                          Text(Utils.numToReadableString(entity.avgLikes)),
                      "Avg. Bookmarks":
                          Text(Utils.numToReadableString(entity.avgBookmarks)),
                      "Avg. Views":
                          Text(Utils.numToReadableString(entity.avgViews)),
                      "Sample Size":
                          Text(Utils.numToReadableString(entity.pids.length)),
                    }),
                  ],
                ),
    );
  }
}
