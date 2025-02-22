import 'package:flutter/material.dart';
import 'package:political_think/common/components/confidence_component.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class ConfidenceSlider extends StatefulWidget {
  final ValueChanged<Confidence>? onConfidenceSelected;
  Confidence? selectedConfidence;
  final Confidence? confidence2;
  final Confidence? confidence3;
  final bool showNull2AsLoading;
  final bool showNull3AsLoading;
  final double width;
  final double height;
  final int? rows;
  final int? columns;
  final bool showUnselected;
  final bool showText;
  final bool showNullBackround;
  final bool wave;
  final bool viral;

  ConfidenceSlider({
    super.key,
    this.selectedConfidence,
    this.confidence2,
    this.confidence3,
    this.onConfidenceSelected,
    this.width = IconSize.large,
    this.height = IconSize.large,
    this.rows,
    this.columns,
    this.showUnselected = true,
    this.showNullBackround = true,
    this.showText = true,
    this.showNull2AsLoading = false,
    this.showNull3AsLoading = false,
    this.wave = false,
    this.viral = false,
  }) : assert(!viral || !wave);

  @override
  State<ConfidenceSlider> createState() => _ConfidenceSliderState();
}

class _ConfidenceSliderState extends State<ConfidenceSlider> {
  bool _isEditing = false;
  double get _width {
    if (_isEditing) {
      return widget.width;
    }
    double count = 0;
    if (widget.selectedConfidence != null) {
      count++;
    }
    if (widget.confidence2 != null || widget.showNull2AsLoading) {
      count++;
    }
    if (widget.confidence3 != null || widget.showNull3AsLoading) {
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
              visible: _isEditing ||
                  widget.selectedConfidence != null ||
                  widget.showNullBackround,
              child: ConfidenceComponent(
                confidence: widget.selectedConfidence,
                width: _width,
                height: widget.height,
                rows: widget.rows,
                columns: widget.columns,
                showUnselected: widget.showUnselected,
                showText: widget.showText,
                showNullBackround: widget.showNullBackround,
                wave: widget.wave,
                viral: widget.viral,
              ),
            ),
            Visibility(
              visible: !_isEditing &&
                  (widget.confidence2 != null || widget.showNull2AsLoading),
              child: widget.confidence3 == null && widget.showNull3AsLoading
                  ? LoadingConfidenceAnimation(
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                      wave: widget.wave,
                    )
                  : ConfidenceComponent(
                      confidence: widget.confidence2,
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                      showNullBackround: widget.showNullBackround,
                      wave: widget.wave,
                    ),
            ),
            Visibility(
              visible: !_isEditing &&
                  (widget.confidence3 != null || widget.showNull3AsLoading),
              child: widget.confidence3 == null && widget.showNull3AsLoading
                  ? LoadingConfidenceAnimation(
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                      wave: widget.wave,
                    )
                  : ConfidenceComponent(
                      confidence: widget.confidence3,
                      width: _width,
                      height: widget.height,
                      rows: widget.rows,
                      columns: widget.columns,
                      showUnselected: widget.showUnselected,
                      showNullBackround: widget.showNullBackround,
                      wave: widget.wave,
                    ),
            ),
          ],
        ),
        SizedBox(
          height: widget.height, //magic number
          width: widget.width,
          child: SfSliderTheme(
            data: const SfSliderThemeData(
                thumbColor: Colors.transparent,
                overlayColor: Colors.transparent,
                thumbRadius: 0,
                overlayRadius: 0),
            child: SfSlider.vertical(
              trackShape: _SfTrackShape(),
              max: 1.0,
              min: 0.0,
              value: widget.selectedConfidence?.value ?? 0.0,
              onChanged: widget.onConfidenceSelected == null
                  ? null
                  : (dynamic newValue) {
                      setState(() {
                        if (widget.selectedConfidence == null) {
                          widget.selectedConfidence =
                              Confidence(value: newValue as double);
                        } else {
                          widget.selectedConfidence =
                              Confidence(value: newValue as double);
                        }
                      });
                    },
              onChangeStart: widget.onConfidenceSelected == null
                  ? null
                  : (value) {
                      setState(() {
                        _isEditing = true;
                      });
                    },
              onChangeEnd: widget.onConfidenceSelected == null
                  ? null
                  : (value) {
                      widget.onConfidenceSelected
                          ?.call(Confidence(value: value as double));
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
// confidence component below the slider.
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
