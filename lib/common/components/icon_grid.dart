import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/entity.dart';
import 'package:political_think/views/entity/entity_list.dart';

class IconGrid extends StatelessWidget {
  final List<Widget>? children;
  final List<String?>? urls;
  final List<Entity>? entities;
  final double size = IconSize.large; // NOT FULLY RESPECTED
  final VoidCallback? onPressed;
  final List<Widget>? _children;
  final int maxItems; // max number of items to show
  IconGrid({
    Key? key,
    this.urls,
    this.onPressed,
    this.entities,
    this.maxItems = 3,
    this.children,
  })  : _children = children ??
            entities
                ?.take(maxItems)
                .map((entity) => ProfileIcon(
                      url: entity.photoURL,
                      radius: IconSize.standard / 2,
                      watch: false,
                      isSelf: false,
                    ))
                .toList() ??
            urls
                ?.take(maxItems)
                .map((url) => ProfileIcon(
                      url: url,
                      radius: IconSize.standard / 2,
                      watch: false,
                      isSelf: false,
                    ))
                .toList(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(_children != null, "IconGrid must have children");

    int totalItems = entities?.length ?? urls?.length ?? children?.length ?? 0;
    int itemCount = min(totalItems, maxItems);
    bool showExtraCell = totalItems > maxItems;
    int crossAxisCount = _calculateCrossAxisCount(totalItems);

    // TODO: MEGA HACK! WIDGET USES ENTURELY MAGIC NUMBERS
    // TODO: only way to center it is with this padding bs
    // Size is 2x2 centering of the grid. eg, if size is 48 we want to pad by 12
    return SizedBox(
      width: size * 1.65,
      height: size,
      child: _children?.isEmpty ?? true
          ? Loading(type: LoadingType.image, width: size * 1.65, height: size)
          : ZTextButton(
              type: ZButtonTypes.area, // icon wraps the grid
              onPressed: onPressed ??
                  (entities != null
                      ? () => context.showModal(EntityListView(
                          eids: entities!.map((e) => e.eid).toList()))
                      : null),
              child: Container(
                height: size,
                width: size,
                padding: _children!.length == 1
                    ? context.blockPaddingSmall
                    : _children!.length == 2
                        ? EdgeInsets.symmetric(vertical: size / 4)
                        : EdgeInsets.zero,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.0, // Ensures the _children are square.
                  ),
                  itemCount: showExtraCell ? itemCount + 1 : itemCount,
                  itemBuilder: (context, index) {
                    // For the extra cell that shows remaining widgets count
                    if (showExtraCell && index == maxItems) {
                      return Center(
                        child: Text(
                          totalItems - maxItems > 9
                              ? "9+"
                              : "+${totalItems - maxItems}",
                          style: context.s,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return _children![index];
                  },
                ),
              ),
            ),
    );
  }

  int _calculateCrossAxisCount(int childCount) {
    if (childCount <= 1) {
      return 1;
    } else {
      return 2;
    }
  }
}
