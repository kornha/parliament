import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/loading_shimmer.dart';
import 'package:political_think/common/components/modal_container.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/extensions.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

enum ZImageSize { small, standard }

class ZImage extends StatelessWidget {
  final String photoURL;
  final ZImageSize imageSize;
  final bool showFullImage;

  const ZImage({
    super.key,
    required this.photoURL,
    this.imageSize = ZImageSize.standard,
    this.showFullImage = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (photoURL.isEmpty) {
      imageWidget = const ZError(type: ErrorType.image);
    } else if (photoURL.endsWith('.svg')) {
      imageWidget = SvgPicture.network(
        photoURL,
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
      imageWidget = Image.network(
        photoURL,
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

    return GestureDetector(
      onTap: () => showFullImage ? _openFullImage(context, photoURL) : null,
      child: imageWidget,
    );
  }

  void _openFullImage(BuildContext context, String url) {
    context.showFullScreenModal(
      useScrollView: false, // hack, see method
      ModalContainer(
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.vertical,
          movementDuration: const Duration(milliseconds: 600),
          // not really needed just for personal UX preference
          dismissThresholds: const <DismissDirection, double>{
            DismissDirection.vertical: 0.55,
          },
          confirmDismiss: (direction) {
            context.pop();
            // TODO: Done with confirmDismiss to avoid error since we cannot remove from state
            return Future.value(false);
          },
          child: PhotoView(
            tightMode: true, // required in dialog
            basePosition: Alignment.center,
            imageProvider: NetworkImage(url),
            backgroundDecoration:
                const BoxDecoration(color: Colors.transparent),
            minScale: PhotoViewComputedScale.contained * 1,
            maxScale: PhotoViewComputedScale.covered * 2,
            loadingBuilder: (context, event) =>
                const Loading(type: LoadingType.image),
          ),
        ),
      ),
    );
  }
}
