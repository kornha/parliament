import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/zapp_bar.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/views/Confidence/Confidence_widget.dart';
import 'package:political_think/views/bias/political_position_widget.dart';

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
                    context.sh,
                    context.sh,
                    Icon(
                      entity.sourceType.icon,
                      size: context.iconSizeStandard,
                      color: context.secondaryColor,
                    ),
                    context.sf,
                    const ZDivider(),
                    context.sh,
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Confidence",
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConfidenceWidget(
                          confidence: entity.confidence,
                          eid: entity.eid,
                          width: context.iconSizeXXXL,
                          height: context.iconSizeXXXL,
                        ),
                      ],
                    ),
                    context.sf,
                    const ZDivider(type: DividerType.SECONDARY),
                    context.sh,
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Bias",
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PoliticalPositionWidget(
                          position: entity.bias,
                          eid: entity.eid,
                          radius: context.iconSizeXXXL / 2,
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
