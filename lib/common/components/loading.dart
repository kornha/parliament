import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:political_think/common/components/credibility_component.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/components/political_component.dart';
import 'package:political_think/common/components/zscaffold.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/political_position.dart';

enum LoadingType {
  tiny,
  small,
  standard,
  large,
  imageSmall,
  image,
  postSmall,
  post
}

class Loading extends StatelessWidget {
  final LoadingType type;
  const Loading({
    Key? key,
    this.type = LoadingType.large,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.image:
        return LoadingShimmer(
          child: Container(
            width: context.imageSize.width,
            height: context.imageSize.height,
            decoration: BoxDecoration(
              color: context.surfaceColor,
            ),
          ),
        );
      case LoadingType.imageSmall:
        return LoadingShimmer(
          child: Container(
            width: context.imageSizeSmall.width,
            height: context.imageSizeSmall.height,
            decoration: BoxDecoration(
              color: context.surfaceColor,
            ),
          ),
        );
      case LoadingType.post:
        return SizedBox(
          width: context.imageSize.width,
          child: Column(
            children: [
              LoadingShimmer(
                child: Container(
                  width: context.imageSize.width,
                  height: context.imageSize.height,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                  ),
                ),
              ),
              context.sh,
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Loading(type: LoadingType.postSmall),
                  Loading(type: LoadingType.postSmall),
                  Loading(type: LoadingType.postSmall),
                ],
              )
            ],
          ),
        );
      case LoadingType.postSmall:
        return LoadingShimmer(
          child: Container(
            width: context.imageSize.width / 3.0 - context.sl.width!,
            height: context.imageSize.height * 1 / 3,
            decoration: BoxDecoration(
              color: context.surfaceColor,
            ),
          ),
        );
      case LoadingType.tiny:
        return Container(
          child: Center(
            child: LoadingPoliticalPositionAnimation(
              size: context.iconSizeTiny,
              duration: const Duration(milliseconds: 1200),
            ),
          ),
        );
      case LoadingType.small:
        return Container(
          child: Center(
            child: LoadingPoliticalPositionAnimation(
              size: context.iconSizeSmall,
              duration: const Duration(milliseconds: 1200),
            ),
          ),
        );
      case LoadingType.standard:
        return Container(
          child: Center(
            child: LoadingPoliticalPositionAnimation(
              size: context.iconSizeStandard,
              duration: const Duration(milliseconds: 1200),
            ),
          ),
        );
      case LoadingType.large:
      default:
        return Container(
          child: Center(
            child: LoadingPoliticalPositionAnimation(
              size: context.iconSizeLarge,
              duration: const Duration(milliseconds: 1200),
            ),
          ),
        );
    }
  }
}

class LoadingPoliticalPositionAnimation extends StatefulWidget {
  final double size;
  final Duration duration;
  final AnimationController? controller;
  final int? rings;
  final double give;
  final int maxCirclesPerRing;
  final bool showUnselected;

  const LoadingPoliticalPositionAnimation({
    Key? key,
    this.size = 50.0,
    this.duration = const Duration(milliseconds: 1200),
    this.controller,
    this.rings,
    this.give = 0.26,
    this.maxCirclesPerRing = 55,
    this.showUnselected = false,
  }) : super(key: key);

  @override
  State<LoadingPoliticalPositionAnimation> createState() =>
      _LoadingPoliticalPositionAnimationState();
}

class _LoadingPoliticalPositionAnimationState
    extends State<LoadingPoliticalPositionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = (widget.controller ??
        AnimationController(vsync: this, duration: widget.duration))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..repeat();
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear)));
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PoliticalComponent(
      showUnselected: widget.showUnselected,
      rings: widget.rings ?? (widget.size >= context.iconSizeStandard ? 3 : 2),
      position:
          PoliticalPosition.fromRadians((1.0 - _animation.value) * pi * 2),
      radius: widget.size / 2,
    );
  }
}

class LoadingCredibilityAnimation extends StatefulWidget {
  final Duration duration;
  final AnimationController? controller;
  final double width;
  final double height;
  final int? rows;
  final int? columns;
  late final int _rows = rows ?? 28;
  late final int _columns = columns ?? width ~/ height * _rows;

  final bool showUnselected;

  LoadingCredibilityAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 1200),
    this.controller,
    required this.width,
    required this.height,
    this.rows,
    this.columns,
    this.showUnselected = false,
  }) : super(key: key);

  @override
  State<LoadingCredibilityAnimation> createState() =>
      _LoadingCredibilityAnimationState();
}

class _LoadingCredibilityAnimationState
    extends State<LoadingCredibilityAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = (widget.controller ??
        AnimationController(vsync: this, duration: widget.duration))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..repeat();
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear)));
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  bool topdown = true;
  double prev = 1.0;

  @override
  Widget build(BuildContext context) {
    if (prev > _animation.value) {
      topdown = !topdown;
    }
    prev = _animation.value;

    return CredibilityComponent(
      width: widget.width,
      height: widget.height,
      credibility: Credibility.fromValue(
          topdown ? 1.0 - _animation.value : _animation.value),
    );
  }
}

class LoadingPage extends StatelessWidget {
  static const location = "/feed";

  const LoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ZScaffold(
      body: Center(child: Loading()),
    );
  }
}
