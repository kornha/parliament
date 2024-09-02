import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/interactive/political_position_joystick.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/services/database.dart';
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

    return entityRef.isLoading
        ? const Loading()
        : entity == null
            ? const ZError()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileIcon(
                    radius: context.iconSizeLarge / 2,
                    eid: widget.eid,
                    // we override onPressed here since we need to pop the context
                    // otherwise we can allow default navigation from ProfileIcon
                    onPressed: () {
                      context.push("${EntityView.location}/${widget.eid}");
                      context.pop();
                    },
                  ),
                  context.sh,
                  // used to even the sides but theres other ways
                  SizedBox.square(dimension: context.iconSizeLarge),
                  const Spacer(),
                  Text(
                    entity.handle,
                    style: context.h3b,
                  ),
                  context.sl,
                  Icon(
                    entity.sourceType.icon,
                    size: context.iconSizeSmall,
                    color: context.secondaryColor,
                    applyTextScaling: true,
                  ),
                  const Spacer(),
                  PoliticalPositionWidget(
                    position: entity.bias,
                    eid: entity.eid,
                  ),
                  context.sh,
                  ConfidenceWidget(
                    confidence: entity.confidence,
                    eid: entity.eid,
                  ),
                ],
              );
  }
}
