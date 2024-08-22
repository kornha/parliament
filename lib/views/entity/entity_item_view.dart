import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/interactive/confidence_slider.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/services/database.dart';
import 'package:political_think/common/util/zimage.dart';
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
                  entity.photoURL != null
                      ? ProfileIcon(
                          eid: widget.eid,
                          // we override onPressed here since we need to pop the context
                          // otherwise we can allow default navigation from ProfileIcon
                          onPressed: () {
                            context
                                .push("${EntityView.location}/${widget.eid}");
                            context.pop();
                          },
                        )
                      : const SizedBox.shrink(),
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
                  // TODO: we need to replace this with confidence widget
                  ConfidenceSlider(
                    showText: entity.confidence != null,
                    selectedConfidence:
                        entity.confidence ?? Confidence(value: 0.5),
                    width: context.iconSizeLarge,
                    height: context.iconSizeLarge,
                    onConfidenceSelected: (conf) {
                      Database.instance().updateEntity(
                          entity.eid, {"adminConfidence": conf.value});
                    },
                  ),
                ],
              );
  }
}
