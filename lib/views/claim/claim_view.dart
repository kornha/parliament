import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/icon_grid.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/zprovider.dart';

class ClaimView extends ConsumerStatefulWidget {
  final String cid;

  const ClaimView({
    super.key,
    required this.cid,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ClaimViewState();
}

class _ClaimViewState extends ConsumerState<ClaimView> {
  @override
  Widget build(BuildContext context) {
    var claimRef = ref.watch(claimProvider(widget.cid));
    var claim = claimRef.value;

    var proListRef = ref.watch(entitiesFromPostsProvider(claim?.pro ?? []));
    var againstListRef =
        ref.watch(entitiesFromPostsProvider(claim?.against ?? []));

    var proList = proListRef.value;
    var againstList = againstListRef.value;

    return claimRef.isLoading
        ? const Loading(type: LoadingType.standard)
        : claim == null
            ? const ZError(type: ErrorType.standard)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  context.sh,
                  Text(
                    claim.value,
                    style: context.l,
                  ),
                  context.sh,
                  Row(
                    children: [
                      proList != null && proList.isNotEmpty
                          ? IconGrid(
                              urls: proList.map((e) => e.photoURL).toList())
                          : Text(
                              "${claim.pro.length}",
                              style: context.al
                                  .copyWith(color: context.secondaryColor),
                            ),
                      const Spacer(),
                      againstList != null && againstList.isNotEmpty
                          ? IconGrid(
                              urls: againstList.map((e) => e.photoURL).toList())
                          : Text(
                              "${claim.against.length}",
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
