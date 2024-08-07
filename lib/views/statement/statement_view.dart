import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/icon_grid.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/zprovider.dart';

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
  @override
  Widget build(BuildContext context) {
    var statementRef = ref.watch(statementProvider(widget.stid));
    var statement = statementRef.value;

    var proListRef = ref.watch(entitiesFromPostsProvider(statement?.pro ?? []));
    var againstListRef =
        ref.watch(entitiesFromPostsProvider(statement?.against ?? []));

    var proList = proListRef.value;
    var againstList = againstListRef.value;

    return statementRef.isLoading
        ? const Loading(type: LoadingType.standard)
        : statement == null
            ? const ZError(type: ErrorType.standard)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  context.sh,
                  Text(
                    statement.value,
                    style: context.l,
                  ),
                  context.sh,
                  Row(
                    children: [
                      proList != null && proList.isNotEmpty
                          ? IconGrid(
                              urls: proList.map((e) => e.photoURL).toList())
                          : Text(
                              "${statement.pro.length}",
                              style: context.al
                                  .copyWith(color: context.secondaryColor),
                            ),
                      const Spacer(),
                      againstList != null && againstList.isNotEmpty
                          ? IconGrid(
                              urls: againstList.map((e) => e.photoURL).toList())
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
