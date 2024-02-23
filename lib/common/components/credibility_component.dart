import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/political_position.dart';

class CredibilityComponent extends StatefulWidget {
  final Credibility? credibility;
  final Credibility? credibility2;
  final Credibility? credibility3;
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

  CredibilityComponent({
    Key? key,
    this.credibility,
    this.credibility2, // deprecated
    this.credibility3, // deprecated
    required this.width,
    required this.height,
    this.fadeAbove = true,
    this.setColor,
    this.decay = 0.77,
    this.rows, // rows and columns must match width and height ratio
    this.columns,
    this.showUnselected = true,
  }) : super(key: key);

  @override
  State<CredibilityComponent> createState() => _CredibilityComponentState();
}

class _CredibilityComponentState extends State<CredibilityComponent> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: CredibilityPainter(
          context: context,
          credibility: widget.credibility,
          credibility2: widget.credibility2,
          credibility3: widget.credibility3,
          width: widget.width,
          height: widget.height,
          setColor: widget.setColor,
          decay: widget.decay,
          fadeAbove: widget.fadeAbove,
          rows: widget.rows ?? 28,
          columns:
              widget.columns ?? (widget.width / widget.height * 28.0).toInt(),
          showUnselected: widget.showUnselected,
        ),
      ),
    );
  }
}

class CredibilityPainter extends CustomPainter {
  final BuildContext context;
  final Credibility? credibility;
  final Credibility? credibility2;
  final Credibility? credibility3;
  final int rows;
  final int columns;
  final bool showUnselected;
  final double width;
  final double height;
  final double decay;
  final Color? setColor;
  final bool fadeAbove;

  CredibilityPainter({
    required this.context,
    this.credibility,
    this.credibility2,
    this.credibility3,
    this.setColor,
    this.fadeAbove = true,
    required this.width,
    required this.height,
    required this.rows, // rows and columns must match width and height ratio
    required this.columns,
    this.decay = 0.77,
    this.showUnselected = true,
  });

  late final _paint = Paint()
    ..color = context.surfaceColor
    ..style = PaintingStyle.fill;

  late final _radiusSmall = min(((width / columns)), (height / rows)) * 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < columns; i++) {
      for (int j = 0; j < rows; j++) {
        var currentCredibility =
            _getCurrentCredibility(i, credibility, credibility2, credibility3);

        //
        var color =
            showUnselected ? context.surfaceColor : context.backgroundColor;
        if (currentCredibility != null) {
          var credibleRow = (rows - 1) -
              (currentCredibility.value / 1.0 * (rows - 1)).toInt();
          double exp = pow(decay, (credibleRow - j).abs()).toDouble();
          color = !fadeAbove && credibleRow > j
              ? Colors.transparent
              : setColor?.withOpacity(exp) ??
                  Color.fromRGBO(
                    currentCredibility.value < 0.5
                        ? 255 * (1.0 - currentCredibility.value) ~/ 1.0
                        : 0,
                    currentCredibility.value >= 0.5
                        ? 255 * currentCredibility.value ~/ 1.0
                        : 0,
                    255 * (1.0 - currentCredibility.value) ~/ 1.0,
                    exp,
                  );
        } else {
          var credibleRow = (rows - 1) - (0.5 * (rows - 1)).toInt();
          double exp = pow(decay, (credibleRow - j).abs()).toDouble();
          color = context.surfaceColor.withOpacity(exp);
        }

        var offsetx = 2 * _radiusSmall * i + _radiusSmall;
        var offsety = 2 * _radiusSmall * j + _radiusSmall;
        canvas.drawCircle(
            Offset(offsetx, offsety), _radiusSmall, _paint..color = color);
      }
    }
  }

  Credibility? _getCurrentCredibility(int i, Credibility? credibility,
      Credibility? credibility2, Credibility? credibility3) {
    if (credibility == null && credibility2 == null && credibility3 == null) {
      return null;
    }
    if (credibility != null && credibility2 == null && credibility3 == null) {
      return credibility;
    }
    if (credibility == null && credibility2 != null && credibility3 == null) {
      return credibility2;
    }
    if (credibility == null && credibility2 == null && credibility3 != null) {
      return credibility3;
    }
    if (credibility != null && credibility2 != null && credibility3 == null) {
      return i % 2 == 0 ? credibility : credibility2;
    }
    if (credibility != null && credibility2 == null && credibility3 != null) {
      return i % 2 == 0 ? credibility : credibility3;
    }
    if (credibility == null && credibility2 != null && credibility3 != null) {
      return i % 2 == 0 ? credibility2 : credibility3;
    }
    if (credibility != null && credibility2 != null && credibility3 != null) {
      return i % 3 == 0
          ? credibility
          : i % 3 == 1
              ? credibility2
              : credibility3;
    }
    return null;
  }

  // USE IF FREQUENTLY UPDATING!
  @override
  bool shouldRepaint(CredibilityPainter oldDelegate) =>
      oldDelegate.credibility?.value != credibility?.value;
}

class PercentComponent extends CredibilityComponent {
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
          credibility: Credibility(value: percent),
        );
}
