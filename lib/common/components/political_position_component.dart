import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';

/// Possible seats of a political position
enum PoliticalOptions {
  all,
  leftRight,
}

class PoliticalPositionComponent extends StatefulWidget {
  final PoliticalPosition? position;
  final PoliticalOptions options;
  final double radius;
  final int rings;
  final double give;
  final double maxCirclesPerRing;
  final bool showUnselected;
  final bool showNullBackround;

  const PoliticalPositionComponent({
    Key? key,
    this.position,
    this.radius = 50,
    this.options = PoliticalOptions.all,
    this.rings = 1,
    this.give = 0.26,
    this.maxCirclesPerRing = 75,
    this.showUnselected = true,
    this.showNullBackround = true,
  }) : super(key: key);

  @override
  State<PoliticalPositionComponent> createState() =>
      _PoliticalPositionComponentState();
}

class _PoliticalPositionComponentState
    extends State<PoliticalPositionComponent> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: CustomPaint(
        painter: PoliticalPainter(
          context: context,
          position: widget.position,
          options: widget.options,
          radius: widget.radius,
          rings: widget.rings,
          maxCirclesPerRing: widget.maxCirclesPerRing,
          showUnselected: widget.showUnselected,
          give: widget.give,
          backgroundColor: widget.showNullBackround && widget.position == null
              ? Palette.teal.withOpacity(0.4)
              : null,
        ),
      ),
    );
  }
}

class PoliticalPainter extends CustomPainter {
  final BuildContext context;
  final PoliticalPosition? position;
  final PoliticalOptions options;
  final double radius;
  final double give;
  final int rings;
  final double maxCirclesPerRing;
  final bool showUnselected;
  final Color? backgroundColor;

  late final double _radiusSmall = radius / (maxCirclesPerRing * 0.4);

  late final _giveScaled = give * pi;

  PoliticalPainter({
    required this.context,
    this.position,
    this.options = PoliticalOptions.all,
    this.radius = 50,
    this.rings = 4,
    this.give = 0.26,
    this.maxCirclesPerRing = 55,
    this.showUnselected = true,
    this.backgroundColor,
  });

  late final _paintOuter = Paint()
    ..color = Colors.transparent
    ..style = PaintingStyle.fill;

  late final _paintInner = Paint()
    ..color = context.surfaceColor
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      _paintOuter,
    );
    Point center = Point(radius, radius);
    for (int i = 0; i < rings; i++) {
      _drawCircles(
        canvas,
        center,
        radius - _radiusSmall * 2 * i,
        maxCirclesPerRing - i * 5,
      );
    }
  }

  // USE IF FREQUENTLY UPDATING!
  @override
  bool shouldRepaint(PoliticalPainter oldDelegate) =>
      oldDelegate.position != position;

  _drawCircles(
    Canvas canvas,
    Point center,
    double distance,
    double count,
  ) {
    for (double rdns = 0; rdns < 2 * pi; rdns += 2 * pi / count) {
      // -distance makes this circle go counter-clockwise which is how we count
      Point point = center + Point(distance * cos(rdns), -distance * sin(rdns));

      PoliticalPosition circlePosition =
          PoliticalPosition(angle: PoliticalPosition.toDegrees(rdns));

      Color color = backgroundColor ?? context.surfaceColor;

      // color only if we are close enough to the political position
      // not to be confused with the geometric position!
      if (position != null &&
          PoliticalPosition.toRadians(position!.distance(circlePosition)) <
              _giveScaled) {
        color = circlePosition.color;
      } else if (!showUnselected) {
        continue;
      }

      // Skip drawing the center and extreme if we are only showing left/right
      if (options == PoliticalOptions.leftRight &&
          (circlePosition.isCenter || circlePosition.isExtreme)) {
        continue;
      }

      canvas.drawCircle(
        Offset(point.x.toDouble(), point.y.toDouble()),
        _radiusSmall,
        _paintInner..color = color,
      );
    }
  }
}
