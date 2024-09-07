import 'package:flutter/material.dart';

import 'joystick.dart';
import 'joystick_controller.dart';
import 'joystick_stick.dart';
import 'joystick_stick_offset_calculator.dart';

/// Allow to place the joystick in any place where user click.
/// Just need to place other widgets as child of [JoystickArea] widget.
class JoystickArea extends StatefulWidget {
  /// The [child] contained by the joystick area.
  final Widget? child;

  /// Initial joystick alignment relative to the joystick area, by default [Alignment.bottomCenter].
  final Alignment initialJoystickAlignment;

  /// Callback, which is called with [period] frequency when the stick is dragged.
  final StickDragCallback listener;

  /// Frequency of calling [listener] from the moment the stick is dragged, by default 100 milliseconds.
  final Duration period;

  /// Widget that renders joystick base, by default [JoystickBase].
  final Widget? base;

  /// Widget that renders joystick stick, it places in the center of [base] widget, by default [JoystickStick].
  final Widget stick;

  /// Mode possible direction
  final JoystickMode mode;

  /// Calculate offset of the stick based on the stick drag start position and the current stick position.
  final StickOffsetCalculator stickOffsetCalculator;

  /// Callback, which is called when the stick starts dragging.
  final Function? onStickDragStart;

  /// Callback, which is called when the stick released.
  final Function? onStickDragEnd;

  const JoystickArea({
    Key? key,
    this.child,
    this.initialJoystickAlignment = Alignment.bottomCenter,
    required this.listener,
    this.period = const Duration(milliseconds: 100),
    this.base,
    this.stick = const JoystickStick(),
    this.mode = JoystickMode.all,
    this.stickOffsetCalculator = const CircleStickOffsetCalculator(),
    this.onStickDragStart,
    this.onStickDragEnd,
  }) : super(key: key);

  @override
  State<JoystickArea> createState() => _JoystickAreaState();
}

class _JoystickAreaState extends State<JoystickArea> {
  final _areaKey = GlobalKey();
  final _joystickKey = GlobalKey();
  final _controller = JoystickController();
  late Alignment _joystickAlignment;

  @override
  void didChangeDependencies() {
    _joystickAlignment = widget.initialJoystickAlignment;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _areaKey,
      onPanStart: _startDrag,
      onPanUpdate: _updateDrag,
      onPanEnd: _endDrag,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Stack(
          children: [
            if (widget.child != null) Align(child: widget.child),
            Align(
              alignment: _joystickAlignment,
              child: Joystick(
                key: _joystickKey,
                controller: _controller,
                listener: widget.listener,
                period: widget.period,
                mode: widget.mode,
                base: widget.base,
                stick: widget.stick,
                onStickDragStart: widget.onStickDragStart,
                onStickDragEnd: widget.onStickDragEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startDrag(DragStartDetails details) {
    final localPosition = details.localPosition;
    final joystickSize = _joystickKey.currentContext!.size!;

    final areaBox = _areaKey.currentContext!.findRenderObject()! as RenderBox;

    final halfWidth = areaBox.size.width / 2;
    final halfHeight = areaBox.size.height / 2;

    final xAlignment =
        (localPosition.dx - halfWidth) / (halfWidth - joystickSize.width / 2);
    final yAlignment = (localPosition.dy - halfHeight) /
        (halfHeight - joystickSize.height / 2);

    setState(() {
      _joystickAlignment = Alignment(xAlignment, yAlignment);
    });
    _controller.start(details.globalPosition);
  }

  void _updateDrag(DragUpdateDetails details) {
    _controller.update(details.globalPosition);
  }

  void _endDrag(DragEndDetails details) {
    setState(() {
      _joystickAlignment = widget.initialJoystickAlignment;
    });

    _controller.end();
  }
}
