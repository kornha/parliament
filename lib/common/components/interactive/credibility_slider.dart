import 'package:flutter/material.dart';
import 'package:political_think/common/components/credibility_component.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class CredibilitySlider extends StatefulWidget {
  final ValueChanged<Credibility>? onCredbilitySelected;
  Credibility? selectedCredibility;
  final Credibility? credibility2;
  final Credibility? credibility3;
  final bool showNull2AsLoading;
  final bool showNull3AsLoading;
  final double width;
  final double height;
  final int? rows;
  final int? columns;
  final bool showUnselected;

  CredibilitySlider({
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
    this.showNull2AsLoading = false,
    this.showNull3AsLoading = false,
  });

  @override
  State<CredibilitySlider> createState() => _CredibilitySliderState();
}

class _CredibilitySliderState extends State<CredibilitySlider> {
  bool _isEditing = false;
  double get _width {
    if (_isEditing) {
      return widget.width;
    }
    double count = 0;
    if (widget.selectedCredibility != null) {
      count++;
    }
    if (widget.credibility2 != null || widget.showNull2AsLoading) {
      count++;
    }
    if (widget.credibility3 != null || widget.showNull3AsLoading) {
      count++;
    }
    if (count == 0) {
      return widget.width;
    }
    return widget.width / count;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Visibility(
              visible: _isEditing || widget.selectedCredibility != null,
              child: CredibilityComponent(
                credibility: widget.selectedCredibility,
                width: _width,
                height: widget.height,
                rows: widget.rows,
                columns: widget.columns,
                showUnselected: widget.showUnselected,
              ),
            ),
            Visibility(
              visible: !_isEditing &&
                  (widget.credibility2 != null || widget.showNull2AsLoading),
              child: widget.credibility3 == null && widget.showNull3AsLoading
                  ? LoadingCredibilityAnimation(
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                    )
                  : CredibilityComponent(
                      credibility: widget.credibility2,
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                    ),
            ),
            Visibility(
              visible: !_isEditing &&
                  (widget.credibility3 != null || widget.showNull3AsLoading),
              child: widget.credibility3 == null && widget.showNull3AsLoading
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
              max: 1.0,
              min: 0.0,
              value: widget.selectedCredibility?.value ?? 0.0,
              onChanged: (dynamic newValue) {
                setState(() {
                  if (widget.selectedCredibility == null) {
                    widget.selectedCredibility =
                        Credibility(value: newValue as double);
                  } else {
                    widget.selectedCredibility =
                        Credibility(value: newValue as double);
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
