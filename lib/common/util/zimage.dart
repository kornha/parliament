import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/extensions.dart';

class ZImage extends StatelessWidget {
  final String imageUrl;

  const ZImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        width: context.imageSize.width,
        height: context.imageSize.height,
        fit: BoxFit.fitHeight,
        placeholderBuilder: (context) => const LoadingShimmer(),
      );
    } else {
      return Image.network(
        imageUrl,
        loadingBuilder: (context, child, loadingProgress) {
          return loadingProgress == null ? child : const LoadingShimmer();
        },
        fit: BoxFit.fitHeight,
        width: context.imageSize.width,
        height: context.imageSize.height,
        errorBuilder: (context, error, stackTrace) {
          return const LoadingShimmer();
        },
      );
    }
  }
}
