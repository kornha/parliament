import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/views/feed/feed.dart';
// Deferred import: the game's code + the Flame engine are split into a separate
// web chunk that only downloads when the user opens this tab. This keeps the
// app's initial page load unaffected by the game.
import 'package:political_think/games/gemtd/game_entry.dart' deferred as gemtd;

class GameView extends ConsumerStatefulWidget {
  const GameView({super.key});

  static const location = "/game";

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = gemtd.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(color: context.secondaryColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Failed to load the game.\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          // On desktop the side nav rail handles leaving the game, so show the
          // game full-bleed. On mobile the bottom nav bar is hidden to give the
          // game full vertical real estate, so we reserve a slim strip above
          // the game for an exit button — this sits in space that would
          // otherwise be empty letterbox, and guarantees it never overlaps the
          // game's own UI.
          if (context.isDesktop) {
            return gemtd.GemTDGame();
          }
          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 22,
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Exit game',
                      onPressed: () => context.go(Feed.location),
                    ),
                  ),
                ),
              ),
              Expanded(child: gemtd.GemTDGame()),
            ],
          );
        },
      ),
    );
  }
}
