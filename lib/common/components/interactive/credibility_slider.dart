import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/components/credibility_component.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import 'joystick.dart';

class CredibilitySlider extends StatefulWidget {
  final ValueChanged<Credibility>? onCredbilitySelected;
  final Credibility? selectedCredibility;
  final Credibility? credibility2;
  final Credibility? credibility3;
  final double width;
  final double height;
  final int? rows;
  final int? columns;
  final bool showUnselected;

  const CredibilitySlider({
    super.key,
    this.selectedCredibility,
    this.credibility2,
    this.credibility3,
    this.onCredbilitySelected,
    required this.width,
    required this.height,
    this.rows,
    this.columns,
    this.showUnselected = true,
  });

  @override
  State<CredibilitySlider> createState() => _CredibilitySliderState();
}

class _CredibilitySliderState extends State<CredibilitySlider> {
  Credibility? _credibility;
  bool _isEditing = false;
  double get _width => _isEditing
      ? widget.width
      : (widget.width - context.sl.width! * 2.0) / 3.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CredibilityComponent(
              credibility: _credibility ?? widget.selectedCredibility,
              width: _width,
              height: widget.height,
              rows: widget.rows,
              columns: widget.columns,
              showUnselected: widget.showUnselected,
            ),
            Visibility(
              visible: !_isEditing,
              child: CredibilityComponent(
                credibility: widget.credibility2,
                width: _width,
                height: widget.height,
                rows: widget.rows,
                columns: widget.columns,
                showUnselected: widget.showUnselected,
              ),
            ),
            Visibility(
              visible: !_isEditing,
              child: widget.credibility3 == null
                  ? LoadingCredibilityAnimation(
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                    )
                  : CredibilityComponent(
                      credibility: widget.credibility3,
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                    ),
            ),
          ],
        ),
        SizedBox(
          height: widget.height, //magic number
          width: widget.width,
          child: SfSliderTheme(
            data: SfSliderThemeData(
                //thumbColor: Colors.transparent,
                //overlayColor: Colors.transparent,
                thumbRadius: 0,
                overlayRadius: 0),
            child: SfSlider.vertical(
              trackShape: _SfTrackShape(),
              max: 10.0,
              min: 0.0,
              value: _credibility?.value ??
                  widget.selectedCredibility?.value ??
                  0.0,
              onChanged: (dynamic newValue) {
                setState(() {
                  if (_credibility == null) {
                    _credibility = Credibility(value: newValue as double);
                  } else {
                    _credibility = Credibility(value: newValue as double);
                  }
                });
              },
              onChangeStart: (value) {
                setState(() {
                  _isEditing = true;
                });
              },
              onChangeEnd: (value) {
                widget.onCredbilitySelected
                    ?.call(Credibility(value: value as double));
                setState(() {
                  _isEditing = false;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

// TODO: in the future should set the track painter. Currently I just
// set the track color to transparent and use a stack to overlay the
// credibility component below the slider.
class _SfTrackShape extends SfTrackShape {
  @override
  void paint(PaintingContext context, Offset offset, Offset? thumbCenter,
      Offset? startThumbCenter, Offset? endThumbCenter,
      {required RenderBox parentBox,
      required SfSliderThemeData themeData,
      SfRangeValues? currentValues,
      dynamic currentValue,
      required Animation<double> enableAnimation,
      required Paint? inactivePaint,
      required Paint? activePaint,
      required TextDirection textDirection}) {
    Paint paint = Paint()..color = Colors.transparent;
    super.paint(context, offset, thumbCenter, startThumbCenter, endThumbCenter,
        parentBox: parentBox,
        themeData: themeData,
        enableAnimation: enableAnimation,
        inactivePaint: paint,
        activePaint: paint,
        textDirection: textDirection);
  }
}
