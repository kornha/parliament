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

// Matches the game's flat action-button idiom (hairline border, small
// radius, no shadows) — defined app-side because the game library is
// deferred and can't be imported statically here.
class _StripButton extends StatelessWidget {
  const _StripButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(2),
        child: InkWell(
          borderRadius: BorderRadius.circular(2),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: context.primaryColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Icon(icon, size: 18, color: context.primaryColor),
          ),
        ),
      ),
    );
  }
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
      backgroundColor: context.backgroundColor,
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
                  style: TextStyle(color: context.primaryColor),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _StripButton(
                        icon: Icons.castle,
                        tooltip: 'All towers',
                        onTap: () => gemtd.TowersView.show(context),
                      ),
                      const SizedBox(width: 6),
                      _StripButton(
                        icon: Icons.close,
                        tooltip: 'Exit game',
                        onTap: () => context.go(Feed.location),
                      ),
                      const SizedBox(width: 8),
                    ],
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
