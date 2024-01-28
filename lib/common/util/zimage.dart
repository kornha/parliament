import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';

enum ZImageSize { small, standard }

class ZImage extends StatelessWidget {
  final String imageUrl;
  final ZImageSize imageSize;
  const ZImage({
    super.key,
    required this.imageUrl,
    this.imageSize = ZImageSize.standard,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const ZError(type: ErrorType.image);
    } else if (imageUrl.endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        width: imageSize == ZImageSize.small
            ? context.imageSizeSmall.width
            : context.imageSize.width,
        height: imageSize == ZImageSize.small
            ? context.imageSizeSmall.height
            : context.imageSize.height,
        fit: BoxFit.fitHeight,
        placeholderBuilder: (context) => Loading(
            type: imageSize == ZImageSize.small
                ? LoadingType.imageSmall
                : LoadingType.image),
      );
    } else {
      return Image.network(
        imageUrl,
        loadingBuilder: (context, child, loadingProgress) {
          return loadingProgress == null
              ? child
              : Loading(
                  type: imageSize == ZImageSize.small
                      ? LoadingType.imageSmall
                      : LoadingType.image);
        },
        fit: BoxFit.fitHeight,
        width: imageSize == ZImageSize.small
            ? context.imageSizeSmall.width
            : context.imageSize.width,
        height: imageSize == ZImageSize.small
            ? context.imageSizeSmall.height
            : context.imageSize.height,
        errorBuilder: (context, error, stackTrace) {
          return ZError(
            type: imageSize == ZImageSize.small
                ? ErrorType.imageSmall
                : ErrorType.image,
          );
        },
      );
    }
  }
}
