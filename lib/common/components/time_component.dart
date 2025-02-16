import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/util/utils.dart';

class TimeComponent extends StatelessWidget {
  final Timestamp time;
  const TimeComponent({
    super.key,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.pq,
      decoration: BoxDecoration(
        // color: context.secondaryColorWithOpacity,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        Utils.toHumanReadableDate(time),
        style: context.as.copyWith(color: context.secondaryColor),
      ),
    );
  }
}
