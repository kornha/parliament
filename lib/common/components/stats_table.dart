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
                      width: context.soc.width,
                      height: context.sd.height,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.key,
                          style: context.mb,
                          textAlign: TextAlign.start,
                        ),
                      ),
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
                        ? Center(
                            child: Text(
                              (entry.value as Text).data ?? '',
                              style: context.as,
                            ),
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
