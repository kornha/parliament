import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/views/Confidence/Confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';
import 'package:political_think/views/entity/entity_view.dart';

class EntityItemView extends ConsumerStatefulWidget {
  const EntityItemView({
    super.key,
    required this.eid,
  });

  final String eid; // should change this watch to parent object

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EntityItemViewState();
}

class _EntityItemViewState extends ConsumerState<EntityItemView> {
  @override
  Widget build(BuildContext context) {
    final entityRef = ref.entityWatch(widget.eid);
    final entity = entityRef.value;

    AsyncValue<Platform?>? platformRef;
    if (entity?.plid != null) {
      platformRef = ref.platformWatch(entity!.plid!);
    }
    var platform = platformRef?.value;

    return entityRef.isLoading
        ? const Loading()
        : entity == null
            ? const ZError()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProfileIcon(
                    radius: context.iconSizeLarge / 2,
                    eid: widget.eid,
                    // we override onPressed here since we need to pop the context
                    // otherwise we can allow default navigation from ProfileIcon
                    onPressed: () {
                      context.route("${EntityView.location}/${widget.eid}");
                      context.pop();
                    },
                  ),
                  context.sh,
                  GestureDetector(
                    child: Text(
                      entity.handle,
                      style: context.h5b,
                    ),
                    onTap: () {
                      context.route("${EntityView.location}/${widget.eid}");
                      context.pop();
                    },
                  ),
                  context.sl,
                  platform?.getIcon(context.iconSizeSmall) ??
                      const SizedBox.shrink(),
                  const Spacer(),
                  PoliticalPositionWidget(
                    position: entity.bias,
                    eid: entity.eid,
                  ),
                  SizedBox(
                      // need this here or the divider will not show
                      height: context.sth.height!,
                      child:
                          const ZDivider(type: DividerType.VERTICAL_SECONDARY)),
                  ConfidenceWidget(
                    confidence: entity.confidence,
                    eid: entity.eid,
                  ),
                ],
              );
  }
}
