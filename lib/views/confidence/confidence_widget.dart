import 'package:flutter/material.dart';
import 'package:political_think/common/components/info_view.dart';
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
  final bool wave; // used for newsworthiness
  final bool viral;
  final bool showModal;

  const ConfidenceWidget({
    super.key,
    this.confidence,
    this.eid,
    this.stid,
    this.height,
    this.width,
    this.enabled = true,
    this.wave = false,
    this.viral = false,
    this.showModal = true,
  }) : assert(!viral || !wave); // xor

  @override
  State<ConfidenceWidget> createState() => _ConfidenceWidgetState();
}

class _ConfidenceWidgetState extends State<ConfidenceWidget> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.showModal
            ? () {
                if (widget.wave) {
                  context.showModal(NewsworthinessView(
                    newsworthiness: widget.confidence,
                  ));
                } else if (widget.viral) {
                  context.showModal(ViralityView(
                    virality: widget.confidence,
                  ));
                } else {
                  context.showModal(ConfidenceView(
                    confidence: widget.confidence,
                  ));
                }
              }
            : null,
        behavior: HitTestBehavior.translucent,
        child: ConfidenceSlider(
          selectedConfidence: widget.confidence,
          width: widget.width ?? context.iconSizeLarge,
          height: widget.height ?? context.iconSizeLarge,
          wave: widget.wave,
          viral: widget.viral,
          onConfidenceSelected: !widget.enabled
              ? null
              : (conf) {
                  if (widget.eid != null) {
                    Database.instance().updateEntity(
                        widget.eid!, {"adminConfidence": conf.value});
                  } else if (widget.stid != null) {
                    Database.instance().updateStatement(
                        widget.stid!, {"adminConfidence": conf.value});
                  }
                },
        ),
      ),
    );
  }
}
