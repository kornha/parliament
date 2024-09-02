import 'package:flutter/material.dart';
import 'package:political_think/common/components/interactive/political_position_joystick.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/services/database.dart';

class PoliticalPositionWidget extends StatefulWidget {
  final PoliticalPosition? position;
  final String? eid;
  final String? stid;
  final double? radius;

  const PoliticalPositionWidget({
    super.key,
    this.position,
    this.eid,
    this.stid,
    this.radius,
  }) : assert((eid != null) != (stid != null)); // xor

  @override
  State<PoliticalPositionWidget> createState() =>
      _PoliticalPositionWidgetState();
}

class _PoliticalPositionWidgetState extends State<PoliticalPositionWidget> {
  @override
  Widget build(BuildContext context) {
    return PoliticalPositionJoystick(
      selectedPosition: widget.position,
      radius: widget.radius ?? context.iconSizeLarge / 2.0,
      onPositionSelected: (conf) {
        if (widget.eid != null) {
          Database.instance()
              .updateEntity(widget.eid!, {"adminBias": conf.angle});
        } else if (widget.stid != null) {
          Database.instance()
              .updateStatement(widget.stid!, {"adminBias": conf.angle});
        }
      },
    );
  }
}
