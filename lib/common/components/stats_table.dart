import 'package:flutter/material.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/extensions.dart';

class StatsTable extends StatelessWidget {
  final Map<String, Widget> map;

  const StatsTable({
    super.key,
    required this.map,
  });

  @override
  Widget build(BuildContext context) {
    final mapEntries = map.entries.toList();

    return Column(
      children: List.generate(mapEntries.length * 2 - 1, (index) {
        if (index % 2 == 0) {
          int mapIndex = index ~/ 2;
          final entry = mapEntries[mapIndex];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: context.ssp.width,
                      child: Text(entry.key,
                          style: context.h6, textAlign: TextAlign.start),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Check if entry.value is a Text widget, and apply style
                    entry.value is Text
                        ? Text(
                            (entry.value as Text).data ?? '',
                            style: context.as,
                          )
                        : entry.value,
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              context.sh,
              const ZDivider(type: DividerType.SECONDARY),
              context.sh,
            ],
          );
        }
      }),
    );
  }
}
