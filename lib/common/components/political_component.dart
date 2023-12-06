import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';

const double _radius = 50;
const double _maxCirclesPerRing = 55;
// 0.4 is magic number
const double _radiusSmall = _radius / (_maxCirclesPerRing * 0.4);
const int _rings = 4;
// give is the amount of area we show around the political position
const double _give = 0.2 * pi;

class PoliticalComponent extends StatelessWidget {
  final PoliticalPosition? position;

  const PoliticalComponent({
    Key? key,
    this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _radius * 2,
      height: _radius * 2,
      child: CustomPaint(
        painter: PoliticalPainter(
          context: context,
          position: position,
        ),
      ),
    );
  }
}

class PoliticalPainter extends CustomPainter {
  final BuildContext context;
  final PoliticalPosition? position;

  PoliticalPainter({
    required this.context,
    this.position,
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
      const Offset(_radius, _radius),
      _radius,
      _paintOuter,
    );
    Point center = const Point(_radius, _radius);
    for (int i = 0; i < _rings; i++) {
      _drawCircles(
        canvas,
        center,
        _radius - _radiusSmall * 2 * i,
        _maxCirclesPerRing - i * 5,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  _drawCircles(Canvas canvas, Point center, double distance, double count) {
    for (double rdns = 0; rdns < 2 * pi; rdns += 2 * pi / count) {
      // -distance makes this circle go counter-clockwise which is how we count
      Point point = center + Point(distance * cos(rdns), -distance * sin(rdns));

      PoliticalPosition circlePosition =
          PoliticalPosition(value: PoliticalPosition.toDegrees(rdns));

      Color color = context.surfaceColor;

      if (position != null &&
          PoliticalPosition.toRadians(position!.distance(circlePosition)) <
              _give) {
        color = circlePosition.color;
      }

      canvas.drawCircle(
        Offset(point.x.toDouble(), point.y.toDouble()),
        _radiusSmall,
        _paintInner..color = color,
      );
    }
  }
}
