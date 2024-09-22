import 'package:flutter/material.dart';
import 'package:political_think/common/components/interactive/confidence_slider.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/services/database.dart';

class ConfidenceWidget extends StatefulWidget {
  final Confidence? confidence;
  final String? eid;
  final String? stid;
  final double? height;
  final double? width;
  final bool enabled;
  final bool jagged; // used for newsworthiness

  const ConfidenceWidget({
    super.key,
    this.confidence,
    this.eid,
    this.stid,
    this.height,
    this.width,
    this.enabled = true,
    this.jagged = false,
  }) : assert((eid != null) != (stid != null) || true); // xor

  @override
  State<ConfidenceWidget> createState() => _ConfidenceWidgetState();
}

class _ConfidenceWidgetState extends State<ConfidenceWidget> {
  @override
  Widget build(BuildContext context) {
    return ConfidenceSlider(
      selectedConfidence: widget.confidence,
      width: widget.width ?? context.iconSizeLarge,
      height: widget.height ?? context.iconSizeLarge,
      jagged: widget.jagged,
      onConfidenceSelected: !widget.enabled
          ? null
          : (conf) {
              if (widget.eid != null) {
                Database.instance()
                    .updateEntity(widget.eid!, {"adminConfidence": conf.value});
              } else if (widget.stid != null) {
                Database.instance().updateStatement(
                    widget.stid!, {"adminConfidence": conf.value});
              }
            },
    );
  }
}
