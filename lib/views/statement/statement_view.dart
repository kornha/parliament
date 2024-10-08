import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/icon_grid.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/views/Confidence/Confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/entity/entity_list.dart';

class StatementView extends ConsumerStatefulWidget {
  final String stid;

  const StatementView({
    super.key,
    required this.stid,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _StatementViewState();
}

class _StatementViewState extends ConsumerState<StatementView> {
  List<Platform>? platforms;

  @override
  Widget build(BuildContext context) {
    var statementRef = ref.watch(statementProvider(widget.stid));
    var statement = statementRef.value;

    var proListRef = ref.watch(entitiesFromPostsProvider(statement?.pro ?? []));
    var againstListRef =
        ref.watch(entitiesFromPostsProvider(statement?.against ?? []));

    var proList = proListRef.value ?? [];
    var againstList = againstListRef.value ?? [];

    List<String> plids = proList
        .where((e) => e.plid != null && e.photoURL == null)
        .map((e) => e.plid!)
        .toList();
    plids.addAll(againstList
        .where((e) => e.plid != null && e.photoURL == null)
        .map((e) => e.plid!)
        .toList());

    // TODO: hack to get the platform URL
    // note that using a provider here causes a loop
    if (plids.isNotEmpty && platforms == null) {
      Database.instance().getPlatforms(plids).then((value) {
        setState(() {
          platforms = value;
        });
      });
    }

    return statementRef.isLoading
        ? const Loading(type: LoadingType.standard)
        : statement == null
            ? const ZError(type: ErrorType.standard)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  context.sh,
                  Row(
                    children: [
                      Expanded(
                        flex: 5, // need as spacer causes issue with text
                        child: Text(
                          statement.value,
                          style: context.l,
                        ),
                      ),
                      const Spacer(),
                      // TODO: we need to replace this with confidence widget
                      Visibility(
                        visible: statement.type == StatementType.claim,
                        child: ConfidenceWidget(
                          confidence: statement.confidence,
                          stid: statement.stid,
                        ),
                      ),
                      Visibility(
                        visible: statement.type == StatementType.opinion,
                        child: PoliticalPositionWidget(
                          position: statement.bias,
                          stid: statement.stid,
                        ),
                      )
                    ],
                  ),
                  context.sh,
                  Row(
                    children: [
                      proList.isNotEmpty
                          ? IconGrid(
                              urls: proList
                                  .map((e) =>
                                      e.photoURL ??
                                      platforms
                                          ?.firstWhere((p) => p.plid == e.plid)
                                          .photoURL)
                                  .toList(),
                              onPressed: () {
                                context.showModal(EntityListView(
                                    eids: proList.map((e) => e.eid).toList()));
                              },
                            )
                          : Text(
                              "${statement.pro.length}",
                              style: context.al
                                  .copyWith(color: context.secondaryColor),
                            ),
                      const Spacer(),
                      againstList.isNotEmpty
                          ? IconGrid(
                              urls: againstList
                                  .map((e) =>
                                      e.photoURL ??
                                      platforms
                                          ?.firstWhere((p) => p.plid == e.plid)
                                          .photoURL)
                                  .toList(),
                              onPressed: () {
                                context.showModal(EntityListView(
                                    eids: againstList
                                        .map((e) => e.eid)
                                        .toList()));
                              },
                            )
                          : Text(
                              "${statement.against.length}",
                              style: context.al
                                  .copyWith(color: context.errorColor),
                            ),
                      context.sh,
                    ],
                  ),
                ],
              );
  }
}
