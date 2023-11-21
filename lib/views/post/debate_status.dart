import 'package:date_count_down/date_count_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/position.dart';
import 'package:political_think/common/models/room.dart';

class DebateStatus extends StatelessWidget {
  const DebateStatus({
    super.key,
    required this.room,
    this.liberalIsLeft = true,
  });

  final Room room;
  final bool liberalIsLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: context.blockMargin,
        decoration: BoxDecoration(
          color:
              room.decision?.winner.toQuadrant().color ?? context.surfaceColor,
          borderRadius: BRadius.standard,
        ),
        height: context.sqd.height,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _getSideCell(context, true),
            Container(
                width: context.sq.width,
                color: room.decision?.winner.toQuadrant().color ??
                    context.backgroundColor),
            const Spacer(),
            _getCenterCell(context),
            const Spacer(),
            Container(
                width: context.sq.width,
                color: room.decision?.winner.toQuadrant().color ??
                    context.backgroundColor),
            _getSideCell(context, false),
          ],
        ));
  }

  _getCenterCell(BuildContext context) {
    switch (room.status) {
      case RoomStatus.waiting:
        return Text("waiting",
            style: context.HS.copyWith(color: context.onSurfaceColor));
      case RoomStatus.locked:
        return Text("message to start",
            style: context.HS.copyWith(color: context.onSurfaceColor));
      case RoomStatus.live:
        return CountdownTimer(
          endTime: room.clock!.end!.millisecondsSinceEpoch,
          widgetBuilder: (context, time) => time == null
              ? Text("time", style: context.HS)
              : Text("${time.sec}",
                  style: context.HS.copyWith(color: context.onSurfaceColor)),
          onEnd: () => print("end"),
        );
      case RoomStatus.judging:
        return Text("Debate is being judged",
            style: context.HS.copyWith(color: context.onSurfaceColor));
      case RoomStatus.finished:
        return Text("${room.decision!.winner.toQuadrant().name} wins",
            style: context.HS.copyWith(color: context.onSurfaceColor));
      case RoomStatus.errored:
        return Text("Failed to get a winner",
            style: context.HS.copyWith(color: context.onSurfaceColor));
      default:
        return Text("-----",
            style: context.HS.copyWith(color: context.onSurfaceColor));
    }
  }

  Widget _getSideCell(BuildContext context, bool leftSide) {
    switch (room.status) {
      case RoomStatus.waiting:
      case RoomStatus.locked:
        return SideContainer(
            leftSide: leftSide,
            color: (leftSide && liberalIsLeft || !leftSide && !liberalIsLeft)
                ? room.leftUsers.isNotEmpty
                    ? Palette.blue
                    : context.surfaceColor
                : room.rightUsers.isNotEmpty
                    ? Palette.red
                    : context.surfaceColor,
            child: (leftSide && liberalIsLeft || !leftSide && !liberalIsLeft) &&
                        room.leftUsers.isNotEmpty ||
                    (leftSide && !liberalIsLeft ||
                            !leftSide && liberalIsLeft) &&
                        room.rightUsers.isNotEmpty
                ? Icon(Icons.chair,
                    color: context.onSurfaceColor, size: IconSize.big)
                : const SizedBox.shrink());
      case RoomStatus.live:
        return const SizedBox.shrink();
      case RoomStatus.judging:
        return const SizedBox.shrink();
      case RoomStatus.finished:
        return SideContainer(
            leftSide: leftSide,
            color: room.decision?.winner.toQuadrant().color ??
                context.surfaceColor,
            child: (leftSide && liberalIsLeft || !leftSide && !liberalIsLeft) &&
                        room.decision?.winner.toQuadrant() == Quadrant.left ||
                    (leftSide && !liberalIsLeft ||
                            !leftSide && liberalIsLeft) &&
                        room.decision?.winner.toQuadrant() == Quadrant.right
                ? Icon(Icons.check,
                    color: context.onSurfaceColor, size: IconSize.big)
                : const SizedBox.shrink());
      case RoomStatus.errored:
      default:
        return const SizedBox.shrink();
    }
  }
}

class SideContainer extends StatelessWidget {
  const SideContainer({
    super.key,
    required this.color,
    required this.child,
    required this.leftSide,
  });

  final Color color;
  final Widget child;
  final bool leftSide;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
            color: color,
            borderRadius: leftSide
                ? const BorderRadius.only(
                    topLeft: Curvature.standard, bottomLeft: Curvature.standard)
                : const BorderRadius.only(
                    topRight: Curvature.standard,
                    bottomRight: Curvature.standard)),
        width: context.sqd.width,
        height: double.maxFinite,
        child: child,
      );
}
