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
  final bool enabled;

  const PoliticalPositionWidget({
    super.key,
    this.position,
    this.eid,
    this.stid,
    this.radius,
    this.enabled = true,
  }) : assert((eid != null) != (stid != null) || !enabled); // xor

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
      onPositionSelected: !widget.enabled
          ? null
          : (conf) {
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
