import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/stats_table.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zexpansion_tile.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/post.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/util/utils.dart';
import 'package:political_think/views/confidence/confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/post/post_item_view.dart';
import 'package:political_think/views/statement/statement_tab_view.dart';

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

    // all statements
    AsyncValue<List<Statement>?> allStatementsRef;
    List<Statement>? allStatements;
    if (entity?.stids.isNotEmpty ?? false) {
      allStatementsRef = ref.statementsWatch(entity!.stids);
      allStatements = allStatementsRef.value;
    }

    AsyncValue<Platform?>? platformRef;
    if (entity?.plid != null) {
      platformRef = ref.platformWatch(entity!.plid!);
    }
    var platform = platformRef?.value;

    return ZScaffold(
      appBar: ZAppBar(showBackButton: true),
      ignoreScrollView: entityRef.isLoading || !entityRef.hasValue,
      body: entityRef.isLoading
          ? const Loading()
          : !entityRef.hasValue
              ? const ZError()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // use url not eid to avoid default routing
                    Visibility(
                      visible: entity?.photoURL != null,
                      child: ProfileIcon(url: entity!.photoURL),
                    ),
                    Visibility(
                        visible: entity.photoURL != null, child: context.sh),
                    Text(
                      entity.handle,
                      style: context.h2b,
                    ),
                    context.sf,
                    platform?.getIcon(context.iconSizeLarge / 2) ??
                        const SizedBox.shrink(),
                    context.sf,
                    const ZDivider(),
                    context.sh,
                    Visibility(
                      visible: allPosts != null && allPosts.isNotEmpty,
                      child: SizedBox(
                        height: context.blockSizeXS.height,
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
                      ),
                    ),
                    Visibility(
                        visible: allPosts != null && allPosts.isNotEmpty,
                        child: const ZDivider()),
                    Visibility(
                      visible:
                          allStatements != null && allStatements.isNotEmpty,
                      child: StatementTabView(statements: allStatements),
                    ),
                    Visibility(
                        visible:
                            allStatements != null && allStatements.isNotEmpty,
                        child: const ZDivider()),
                    ZExpansionTile(
                      initiallyExpanded: true,
                      title: Text("Stats", style: context.h4),
                      children: [
                        StatsTable(
                          map: {
                            "Confidence": ConfidenceWidget(
                              confidence: entity.confidence,
                              eid: entity.eid,
                              enabled: ref.isAdmin,
                            ),
                            "Bias": PoliticalPositionWidget(
                                position: entity.bias,
                                eid: entity.eid,
                                enabled: ref.isAdmin),
                            if (entity.avgReplies != null)
                              "Avg. Replies": Text(
                                  Utils.numToReadableString(entity.avgReplies)),
                            if (entity.avgReposts != null)
                              "Avg. Reposts": Text(
                                  Utils.numToReadableString(entity.avgReposts)),
                            if (entity.avgLikes != null)
                              "Avg. Likes": Text(
                                  Utils.numToReadableString(entity.avgLikes)),
                            if (entity.avgBookmarks != null)
                              "Avg. Bookmarks": Text(Utils.numToReadableString(
                                  entity.avgBookmarks)),
                            if (entity.avgViews != null)
                              "Avg. Views": Text(
                                  Utils.numToReadableString(entity.avgViews)),
                            "Sample Size": Text(
                                Utils.numToReadableString(entity.pids.length)),
                          },
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
