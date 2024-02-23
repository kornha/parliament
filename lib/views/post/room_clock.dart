import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/index.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/credibility_component.dart';
import 'package:political_think/common/components/profile_icon.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/room.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/zprovider.dart';

class RoomClock extends ConsumerStatefulWidget {
  const RoomClock({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RoomClockState();
}

class _RoomClockState extends ConsumerState<RoomClock> {
  @override
  Widget build(BuildContext context) {
    PoliticalPosition? userPos = widget.room.leftUsers.contains(ref.user().uid)
        ? PoliticalPosition.left()
        : widget.room.rightUsers.contains(ref.user().uid)
            ? PoliticalPosition.right()
            : widget.room.centerUsers.contains(ref.user().uid)
                ? PoliticalPosition.center()
                : widget.room.extremeUsers.contains(ref.user().uid)
                    ? PoliticalPosition.extreme()
                    : null;
    bool invertedOuter =
        (userPos?.isLeft ?? false) || (userPos?.isExtreme ?? false);
    bool invertInner =
        (userPos?.isCenter ?? false) || (userPos?.isExtreme ?? false);

    var size = context.st.height!;
    var nonEmptySides = (widget.room.leftUsers.isNotEmpty ? 1 : 0) +
        (widget.room.rightUsers.isNotEmpty ? 1 : 0) +
        (widget.room.centerUsers.isNotEmpty ? 1 : 0) +
        (widget.room.extremeUsers.isNotEmpty ? 1 : 0);

    // done for convenience later
    var positions = [
      _getCellPosition(widget.room, 0, invertedOuter, invertInner),
      _getCellPosition(widget.room, 1, invertedOuter, invertInner),
      _getCellPosition(widget.room, 2, invertedOuter, invertInner),
      _getCellPosition(widget.room, 3, invertedOuter, invertInner),
    ];

    return Container(
      margin: context.blockMargin,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BRadius.standard,
      ),
      height: size,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            replacement: SizedBox.square(dimension: size),
            visible: nonEmptySides > 1 ||
                nonEmptySides == 1 &&
                    (!invertedOuter &&
                            (widget.room.leftUsers.isNotEmpty ||
                                widget.room.extremeUsers.isNotEmpty) ||
                        invertedOuter &&
                            (widget.room.rightUsers.isNotEmpty ||
                                widget.room.centerUsers.isNotEmpty)),
            child: ClockSide(
              position: positions[0],
              size: size,
              uids: widget.room.usersByQuadrant(positions[0].quadrant),
              score: widget.room.scoreByQuadrant(positions[0].quadrant),
            ),
          ),
          Visibility(
            visible: nonEmptySides > 2 &&
                ((widget.room.extremeUsers.isNotEmpty &&
                        !invertedOuter &&
                        !invertInner) ||
                    (widget.room.centerUsers.isNotEmpty &&
                        invertedOuter &&
                        !invertInner) ||
                    (widget.room.rightUsers.isNotEmpty &&
                        invertedOuter &&
                        invertInner) ||
                    (widget.room.leftUsers.isNotEmpty &&
                        !invertedOuter &&
                        invertInner)),
            child: ClockSide(
              position: positions[1],
              size: size,
              uids: widget.room.usersByQuadrant(positions[1].quadrant),
              score: widget.room.scoreByQuadrant(positions[1].quadrant),
            ),
          ),
          const Spacer(),
          _getCenterCell(context),
          const Spacer(),
          Visibility(
            visible: nonEmptySides > 2 &&
                ((widget.room.extremeUsers.isNotEmpty &&
                        invertedOuter &&
                        !invertInner) ||
                    (widget.room.centerUsers.isNotEmpty &&
                        !invertedOuter &&
                        !invertInner) ||
                    (widget.room.rightUsers.isNotEmpty &&
                        !invertedOuter &&
                        invertInner) ||
                    (widget.room.leftUsers.isNotEmpty &&
                        invertedOuter &&
                        invertInner)),
            child: ClockSide(
              position: positions[2],
              size: size,
              uids: widget.room.usersByQuadrant(positions[2].quadrant),
              score: widget.room.scoreByQuadrant(positions[2].quadrant),
            ),
          ),
          Visibility(
            replacement: SizedBox.square(dimension: size),
            visible: nonEmptySides > 1 ||
                nonEmptySides == 1 &&
                    (invertedOuter &&
                            (widget.room.leftUsers.isNotEmpty ||
                                widget.room.extremeUsers.isNotEmpty) ||
                        !invertedOuter &&
                            (widget.room.rightUsers.isNotEmpty ||
                                widget.room.centerUsers.isNotEmpty)),
            child: ClockSide(
              position: positions[3],
              size: size,
              uids: widget.room.usersByQuadrant(positions[3].quadrant),
              score: widget.room.scoreByQuadrant(positions[3].quadrant),
            ),
          ),
        ],
      ),
    );
  }

  _getCenterCell(BuildContext context) {
    switch (widget.room.status) {
      case RoomStatus.waiting:
        return Text("waiting",
            style: context.ah3.copyWith(color: context.primaryColor));
      case RoomStatus.live:
        return CountdownTimer(
          endTime: widget.room.clock!.end!.millisecondsSinceEpoch,
          widgetBuilder: (context, time) => time == null
              ? Text("time", style: context.ah3)
              : Text("${time.sec}",
                  style: context.ah3.copyWith(color: context.primaryColor)),
          onEnd: () => print("end"),
        );
      case RoomStatus.judging:
        return Text("judging",
            style: context.ah3.copyWith(color: context.primaryColor));
      case RoomStatus.finished:
        String text = widget.room.winningPosition != null
            ? "${widget.room.winningPosition!.quadrant.name} wins"
            : widget.room.winners != null && widget.room.winners!.isEmpty
                ? "draw"
                : "";
        return Text(text,
            style: context.ah3.copyWith(
              color: widget.room.winningPosition?.color ?? context.primaryColor,
            ));
      case RoomStatus.errored:
        return Text("error",
            style: context.ah3.copyWith(color: context.errorColor));
      default:
        return Text("-----",
            style: context.h3.copyWith(color: context.primaryColor));
    }
  }

  PoliticalPosition _getCellPosition(
      Room room, int cellNumber, bool invertedOuter, bool invertInner) {
    if (cellNumber == 0) {
      invertedOuter = !invertedOuter;
    } else if (cellNumber == 1) {
      invertInner = !invertInner;
    }

    if (cellNumber == 1 || cellNumber == 2) {
      return invertedOuter
          ? !invertInner
              ? PoliticalPosition.extreme()
              : PoliticalPosition.left()
          : !invertInner
              ? PoliticalPosition.center()
              : PoliticalPosition.right();
    }

    return invertedOuter
        ? !invertInner
            ? widget.room.leftUsers.isNotEmpty
                ? PoliticalPosition.left()
                : widget.room.extremeUsers.isNotEmpty
                    ? PoliticalPosition.extreme()
                    : PoliticalPosition.center()
            : widget.room.rightUsers.isNotEmpty
                ? PoliticalPosition.right()
                : widget.room.centerUsers.isNotEmpty
                    ? PoliticalPosition.center()
                    : PoliticalPosition.extreme()
        : !invertInner
            ? widget.room.rightUsers.isNotEmpty
                ? PoliticalPosition.right()
                : widget.room.centerUsers.isNotEmpty
                    ? PoliticalPosition.center()
                    : PoliticalPosition.extreme()
            : widget.room.leftUsers.isNotEmpty
                ? PoliticalPosition.left()
                : widget.room.extremeUsers.isNotEmpty
                    ? PoliticalPosition.extreme()
                    : PoliticalPosition.center();
  }
}

class ClockSide extends StatelessWidget {
  const ClockSide({
    super.key,
    required this.size,
    required this.position,
    this.uids = const [],
    this.score = 0.0,
  });

  final PoliticalPosition position;
  final double size;
  final double score;
  final List<String> uids;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        //backbound
        PercentComponent(
          width: size,
          height: size,
          color: position.color,
          percent: score,
        ),
        Container(
          padding: context.blockPaddingSmall,
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Curvature.little)),
          width: size,
          height: double.maxFinite, // height controlled by parent
          child: uids.isNotEmpty
              ? ClockSideGrid(
                  position: position,
                  size: size - context.blockPaddingSmall.horizontal,
                  children: uids
                      .map((uid) => ProfileIcon(
                            uid: uid,
                            size: context.iconSizeSmall,
                            watch: false,
                          ))
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// Define a custom widget that takes a list of widgets and a size.
class ClockSideGrid extends StatelessWidget {
  final List<Widget> children;
  final double size;
  final PoliticalPosition position;

  const ClockSideGrid({
    Key? key,
    required this.children,
    required this.size,
    required this.position,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the number of items to display and if an extra cell is needed
    int maxItems = 4;
    int itemCount = children.length >= maxItems ? maxItems : children.length;
    bool showExtraCell = children.length > maxItems;
    int crossAxisCount = _calculateCrossAxisCount(itemCount);

    // TODO: only way to center it is with this padding bs
    // Size is 2x2 centering of the grid. eg, if size is 48 we want to pad by 12
    return Container(
      padding: children.length == 1
          ? context.blockPaddingSmall
          : children.length == 2
              ? EdgeInsets.symmetric(vertical: size / 4)
              : EdgeInsets.zero,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0, // Ensures the children are square.
        ),
        itemCount: showExtraCell ? itemCount + 1 : itemCount,
        itemBuilder: (context, index) {
          // For the extra cell that shows remaining widgets count
          if (showExtraCell && index == maxItems - 1) {
            return Center(
              child: Text(
                (children.length - 3).toString(),
                style: (children.length - 3) > 9 ? context.as : context.al,
                textAlign: TextAlign.center,
              ),
            );
          }
          return children[index];
        },
      ),
    );
  }
}

int _calculateCrossAxisCount(int childCount) {
  if (childCount <= 1) {
    return 1;
  } else {
    return 2;
  }
}
