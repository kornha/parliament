import 'package:flutter/material.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';

import 'joystick.dart';

class PoliticalPositionJoystick extends StatefulWidget {
  final PoliticalOptions options;
  final ValueChanged<PoliticalPosition>? onPositionSelected;
  final PoliticalPosition? selectedPosition;
  final double radius;
  final int rings;
  final double give;
  final double maxCirclesPerRing;
  final bool showUnselected;
  final bool showStick;
  final bool showNullBackround;

  const PoliticalPositionJoystick({
    super.key,
    this.selectedPosition,
    this.onPositionSelected,
    this.options = PoliticalOptions.all,
    this.radius = 50,
    this.rings = 1,
    this.give = 0.25,
    this.maxCirclesPerRing = 75,
    this.showUnselected = true,
    this.showStick = false,
    this.showNullBackround = true,
  });

  @override
  State<PoliticalPositionJoystick> createState() =>
      _PoliticalPositionJoystickState();
}

class _PoliticalPositionJoystickState extends State<PoliticalPositionJoystick> {
  PoliticalPosition? _position;
  // somewhat duplicated logic but colors and triggers are different
  final int _period = 100;
  final int _holdPeriod = 100; // 100 means no hold period

  int _counter = 0;
  bool _shouldTrigger = false;
  PoliticalPosition? _lastPosition;

  @override
  Widget build(BuildContext context) {
    return Joystick(
      mode: widget.options == PoliticalOptions.leftRight
          ? JoystickMode.horizontal
          : JoystickMode.all,
      stick: Container(
        width: widget.radius,
        height: widget.radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.showStick
                  ? context.surfaceColor.withOpacity(0.5)
                  : Colors.transparent,
              spreadRadius: 1,
              blurRadius: 1,
              offset: const Offset(0, 1),
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.showStick ? context.surfaceColor : Colors.transparent,
              widget.showStick ? context.backgroundColor : Colors.transparent,
            ],
          ),
        ),
      ),
      base: PoliticalComponent(
        position: _position ?? widget.selectedPosition,
        options: widget.options,
        radius: widget.radius,
        rings: widget.rings,
        give: widget.give,
        maxCirclesPerRing: widget.maxCirclesPerRing,
        showUnselected: widget.showUnselected,
        showNullBackround: widget.showNullBackround,
      ),
      period: Duration(milliseconds: _period),
      listener: (StickDragDetails details) {
        setState(() {
          _position = PoliticalPosition.fromCoordinate(details.x, details.y);
        });
        if (details.x == 0 && details.y == 0 && _shouldTrigger) {
          widget.onPositionSelected?.call(_lastPosition!);
          _shouldTrigger = false;
        }
        if (_lastPosition == null) {
          _lastPosition = _position;
        } //
        else if (_position != null &&
            _lastPosition != null &&
            _position!.quadrant == _lastPosition!.quadrant) {
          _counter++;
          if (_period * (_counter + 1) >= _holdPeriod) {
            _lastPosition = _position;
            _shouldTrigger = true;
            _counter = 0;
          }
        } //
        else {
          _counter = 0;
          _lastPosition = null;
          _shouldTrigger = false;
        }
      },
    );
  }
}
