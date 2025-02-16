import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:political_think/common/components/zdivider.dart';
import 'package:political_think/common/components/ztext_button.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

class ZListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final CarouselOptions? options;
  final bool singleItem;
  final bool horizontal;

  const ZListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.singleItem = false,
    this.horizontal = true,
    this.options,
  }) : super(key: key);

  @override
  _ZListViewState createState() => _ZListViewState();
}

class _ZListViewState extends State<ZListView> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // If not horizontal, just return a vertical ListView.
    if (!widget.horizontal) {
      return ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (context, index) =>
            const ZDivider(type: DividerType.SECONDARY),
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      );
    }

    // Build the carousel.
    final carousel = CarouselSlider.builder(
      carouselController: _carouselController,
      itemCount: widget.itemCount,
      itemBuilder: (context, index, realIndex) {
        return widget.itemBuilder(context, index);
      },
      options: widget.options ??
          CarouselOptions(
            height: context.blockSize.height,
            viewportFraction: widget.singleItem
                ? 1.0
                : context.isDesktop
                    ? 0.5
                    : 0.8,
            padEnds: false,
            pageSnapping: false,
            enableInfiniteScroll: false,
            scrollPhysics: context.isDesktopOS
                ? const NeverScrollableScrollPhysics()
                : null,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
    );

    // If singleItem is true, add the indicator row below the carousel.
    final Widget carouselWithIndicators = widget.singleItem
        ? Stack(
            alignment: Alignment.bottomCenter,
            children: [
              carousel,
              context.sh,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.itemCount, (index) {
                  return Container(
                    width: context.sd.width!,
                    height: Thickness.huge,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? context.primaryColor
                          : context.surfaceColor,
                    ),
                  );
                }),
              ),
            ],
          )
        : carousel;

    // For web, include arrow buttons on the sides.
    if (kIsWeb) {
      return Stack(
        children: [
          if (context.isMobileOS) carouselWithIndicators,
          Row(
            children: [
              ZTextButton(
                type: ZButtonTypes.iconSpace,
                onPressed: () {
                  _carouselController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(
                  Icons.chevron_left,
                  size: context.iconSizeLarge,
                  color: context.isMobileOS
                      ? Colors.transparent
                      : context.primaryColorWithOpacity,
                ),
              ),
              context.isMobileOS // to hide buttons on mobile OS
                  ? const Spacer()
                  : Expanded(child: carouselWithIndicators),
              ZTextButton(
                type: ZButtonTypes.iconSpace,
                onPressed: () {
                  _carouselController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(
                  Icons.chevron_right,
                  size: context.iconSizeLarge,
                  color: context.isMobileOS
                      ? Colors.transparent
                      : context.primaryColorWithOpacity,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return carouselWithIndicators;
    }
  }
}
