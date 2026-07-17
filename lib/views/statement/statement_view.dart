import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/icon_grid.dart';
import 'package:political_think/common/components/labeled_score.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/statement.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/views/confidence/confidence_widget.dart';
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
                      // Unmeasured claims read as "unverified" rather than
                      // implying a computed 0.50.
                      Visibility(
                        visible: statement.type == StatementType.claim,
                        child: LabeledScore(
                          label: statement.confidence == null
                              ? "unverified"
                              : "trust",
                          dim: statement.confidence == null,
                          child: ConfidenceWidget(
                            confidence: statement.confidence,
                            stid: statement.stid,
                            enabled: ref.isAdmin,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: statement.type == StatementType.opinion,
                        child: LabeledScore(
                          label: statement.bias == null ? "unrated" : "lean",
                          dim: statement.bias == null,
                          child: PoliticalPositionWidget(
                            position: statement.bias,
                            stid: statement.stid,
                            enabled: ref.isAdmin,
                          ),
                        ),
                      )
                    ],
                  ),
                  context.sh,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (proList.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "pro ${statement.pro.length}",
                              style:
                                  context.as.copyWith(color: Palette.green),
                            ),
                            const SizedBox(height: Margins.least),
                            IconGrid(entities: proList),
                          ],
                        ),
                      const Spacer(),
                      if (againstList.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "against ${statement.against.length}",
                              style: context.as.copyWith(color: Palette.red),
                            ),
                            const SizedBox(height: Margins.least),
                            IconGrid(entities: againstList),
                          ],
                        ),
                      context.sh,
                    ],
                  ),
                ],
              );
  }
}
