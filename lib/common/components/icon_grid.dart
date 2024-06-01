import 'package:flutter/material.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

class IconGrid extends StatelessWidget {
  final List<Widget>? children;
  final List<String?>? urls;
  final double size;

  IconGrid({
    Key? key,
    this.size = IconSize.large,
    this.urls,
    List<Widget>? children,
  })  : children = children ??
            urls
                ?.map((url) => ProfileIcon(
                      url: url,
                      radius: IconSize.small / 2,
                      watch: false,
                      defaultToSelf: false,
                    ))
                .toList(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(children != null, "IconGrid must have children");

    // Calculate the number of items to display and if an extra cell is needed
    int maxItems = 4;
    int itemCount = children!.length >= maxItems ? maxItems : children!.length;
    bool showExtraCell = children!.length > maxItems;
    int crossAxisCount = _calculateCrossAxisCount(itemCount);

    // TODO: only way to center it is with this padding bs
    // Size is 2x2 centering of the grid. eg, if size is 48 we want to pad by 12
    return Container(
      height: size,
      width: size,
      padding: children!.length == 1
          ? context.blockPaddingSmall
          : children!.length == 2
              ? EdgeInsets.symmetric(vertical: size / 4)
              : EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0, // Ensures the children are square.
        ),
        itemCount: showExtraCell ? itemCount + 1 : itemCount,
        itemBuilder: (context, index) {
          // For the extra cell that shows remaining widgets count
          if (showExtraCell && index == maxItems - 1) {
            return Center(
              child: Text(
                (children!.length - 3).toString(),
                style: (children!.length - 3) > 9 ? context.as : context.al,
                textAlign: TextAlign.center,
              ),
            );
          }
          return children![index];
        },
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
