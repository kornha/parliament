import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/confidence.dart';

class ConfidenceComponent extends StatefulWidget {
  final Confidence? confidence;
  final Confidence? confidence2;
  final Confidence? confidence3;
  final double width;
  final double height;
  final int? rows;
  final int? columns;
  late final int _rows = rows ?? 28;
  late final int _columns = columns ?? width ~/ height * _rows;
  final bool showUnselected;
  final Color? setColor;
  final double decay;
  final bool fadeAbove;
  final bool showEndRows;
  final bool showText;
  final bool showNullBackround;
  final bool jagged;
  final bool horizontal; // New flag added here

  ConfidenceComponent({
    Key? key,
    this.confidence,
    this.confidence2, // deprecated
    this.confidence3, // deprecated
    required this.width,
    required this.height,
    this.fadeAbove = true,
    this.setColor,
    this.decay = 0.77,
    this.rows, // rows and columns must match width and height ratio
    this.columns,
    this.showUnselected = true,
    this.showEndRows = false,
    this.showText = false,
    this.showNullBackround = true,
    this.jagged = false,
    this.horizontal = false, // Initialize the new flag
  }) : super(key: key);

  @override
  State<ConfidenceComponent> createState() => _ConfidenceComponentState();
}

class _ConfidenceComponentState extends State<ConfidenceComponent> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: ConfidencePainter(
              context: context,
              confidence: widget.confidence ??
                  (widget.showNullBackround
                      ? const Confidence(value: 0.5)
                      : null),
              confidence2: widget.confidence2,
              confidence3: widget.confidence3,
              width: widget.width,
              height: widget.height,
              setColor: widget.setColor,
              decay: widget.decay,
              fadeAbove: widget.fadeAbove,
              rows: widget.rows ?? 28,
              columns: widget.columns ??
                  (widget.width / widget.height * 28.0).toInt(),
              showUnselected: widget.showUnselected,
              showEndRows: widget.showEndRows,
              jagged: widget.jagged,
              horizontal: widget.horizontal, // Pass the flag to the painter
            ),
          ),
        ),
        Visibility(
          visible: widget.showText && widget.confidence != null,
          child: Text(
            widget.confidence.toString(),
            style:
                widget.width > context.iconSizeLarge ? context.am : context.as,
          ),
        ),
      ],
    );
  }
}

class ConfidencePainter extends CustomPainter {
  final BuildContext context;
  final Confidence? confidence;
  final Confidence? confidence2;
  final Confidence? confidence3;
  final int rows;
  final int columns;
  final bool showUnselected;
  final double width;
  final double height;
  final double decay;
  final Color? setColor;
  final bool fadeAbove;
  final bool showEndRows;
  final bool jagged;
  final bool horizontal; // New flag added here

  ConfidencePainter({
    required this.context,
    this.confidence,
    this.confidence2,
    this.confidence3,
    this.setColor,
    this.fadeAbove = true,
    required this.width,
    required this.height,
    required this.rows, // rows and columns must match width and height ratio
    required this.columns,
    this.decay = 0.77,
    this.showUnselected = true,
    this.showEndRows = true,
    this.jagged = false,
    this.horizontal = false, // Initialize the new flag
  });

  late final _paint = Paint()
    ..color = context.surfaceColor
    ..style = PaintingStyle.fill;

  late final _radiusSmall = min((width / columns), (height / rows)) * 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    int dimension = horizontal ? columns : rows;

    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        var currentConfidence =
            _getCurrentConfidence(i, confidence, confidence2, confidence3);

        var color =
            showUnselected ? context.surfaceColor : context.backgroundColor;

        if (currentConfidence != null) {
          var basePosition = horizontal
              ? (currentConfidence.value * (dimension - 1)).toInt()
              : (dimension - 1) -
                  (currentConfidence.value * (dimension - 1)).toInt();

          int crediblePosition;

          if (jagged) {
            var amplitude = (dimension * 0.15).toInt();
            var frequency = 0.845;
            var wave =
                (sin((horizontal ? j : i) * frequency) * amplitude).toInt();
            crediblePosition = basePosition + wave;
          } else {
            crediblePosition = basePosition;
          }

          double exp = pow(
            decay,
            (crediblePosition - (horizontal ? i : j)).abs(),
          ).toDouble();

          color = !fadeAbove && crediblePosition > (horizontal ? i : j)
              ? Colors.transparent
              : setColor?.withOpacity(exp) ??
                  currentConfidence.color.withOpacity(exp);

          if (showEndRows) {
            if ((horizontal ? i : j) == 0) {
              color = Palette.green;
            } else if ((horizontal ? i : j) == (dimension - 1)) {
              color = Palette.purple;
            }
          }
        }

        var offsetx = 2 * _radiusSmall * i + _radiusSmall;
        var offsety = 2 * _radiusSmall * j + _radiusSmall;
        canvas.drawCircle(
          Offset(offsetx, offsety),
          _radiusSmall,
          _paint..color = color,
        );
      }
    }
  }

  Confidence? _getCurrentConfidence(int i, Confidence? confidence,
      Confidence? confidence2, Confidence? confidence3) {
    if (confidence == null && confidence2 == null && confidence3 == null) {
      return null;
    }
    if (confidence != null && confidence2 == null && confidence3 == null) {
      return confidence;
    }
    if (confidence == null && confidence2 != null && confidence3 == null) {
      return confidence2;
    }
    if (confidence == null && confidence2 == null && confidence3 != null) {
      return confidence3;
    }
    if (confidence != null && confidence2 != null && confidence3 == null) {
      return i % 2 == 0 ? confidence : confidence2;
    }
    if (confidence != null && confidence2 == null && confidence3 != null) {
      return i % 2 == 0 ? confidence : confidence3;
    }
    if (confidence == null && confidence2 != null && confidence3 != null) {
      return i % 2 == 0 ? confidence2 : confidence3;
    }
    if (confidence != null && confidence2 != null && confidence3 != null) {
      return i % 3 == 0
          ? confidence
          : i % 3 == 1
              ? confidence2
              : confidence3;
    }
    return null;
  }

  // USE IF FREQUENTLY UPDATING!
  @override
  bool shouldRepaint(ConfidencePainter oldDelegate) =>
      oldDelegate.confidence?.value != confidence?.value;
}

class PercentComponent extends ConfidenceComponent {
  PercentComponent({
    Key? key,
    required width,
    required height,
    required color,
    required double percent,
    decay = 0.83,
    fadeAbove = false,
    showUnselected = false,
  }) : super(
          key: key,
          width: width,
          height: height,
          showUnselected: showUnselected,
          setColor: color,
          decay: decay,
          fadeAbove: fadeAbove,
          confidence: Confidence(value: percent),
        );
}
