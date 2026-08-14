import 'package:flutter/material.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/util/zimage.dart';
import 'package:video_player/video_player.dart';

/// Poster-frame thumbnail with a play badge; tapping opens a fullscreen
/// player that streams straight from the source CDN (no storage cost).
/// If playback fails (media URLs can rot), the dialog shows a notice and
/// the user still has the post's source link to watch on the platform.
class ZVideo extends StatelessWidget {
  final String photoURL; // poster frame, may be empty
  final String videoURL;
  final ZImageSize imageSize;

  const ZVideo({
    super.key,
    required this.photoURL,
    required this.videoURL,
    this.imageSize = ZImageSize.standard,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          barrierColor: Colors.black87,
          builder: (_) => _ZVideoDialog(videoURL: videoURL),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ZImage(photoURL: photoURL, imageSize: imageSize),
            Container(
              padding: const EdgeInsets.all(Margins.half),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: imageSize == ZImageSize.small
                    ? IconSize.standard
                    : IconSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZVideoDialog extends StatefulWidget {
  final String videoURL;

  const _ZVideoDialog({required this.videoURL});

  @override
  State<_ZVideoDialog> createState() => _ZVideoDialogState();
}

class _ZVideoDialogState extends State<_ZVideoDialog> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoURL))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(Margins.half),
      child: _failed
          ? Padding(
              padding: const EdgeInsets.all(Margins.twice),
              child: Text(
                "Could not play this video.\nOpen the post's source to watch.",
                textAlign: TextAlign.center,
                style: context.l.copyWith(color: Colors.white),
              ),
            )
          : !_controller.value.isInitialized
              ? const Loading()
              : Stack(
                  alignment: Alignment.topRight,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      }),
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
    );
  }
}
