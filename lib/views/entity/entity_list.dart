import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/modal_container.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/views/entity/entity_item_view.dart';

class EntityListView extends ConsumerStatefulWidget {
  final List<String> eids;

  const EntityListView({
    Key? key,
    this.eids = const [],
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EntityListViewState();
}

class _EntityListViewState extends ConsumerState<EntityListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.eids.isEmpty) {
      return const Center(child: Text("No items available"));
    }

    // In separated listview, single item isnt centered
    if (widget.eids.length == 1) {
      return EntityItemView(eid: widget.eids.first);
    }

    // For multiple items, display the ListView as usual
    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) =>
          const ZDivider(type: DividerType.SECONDARY),
      itemCount: widget.eids.length,
      itemBuilder: (context, index) {
        return EntityItemView(eid: widget.eids[index]);
      },
    );
  }
}
