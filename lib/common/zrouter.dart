import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/znavigation_scaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/views/feed/feed.dart';
import 'package:political_think/views/games/games.dart';
import 'package:political_think/views/login/login.dart';
import 'package:political_think/views/message/message.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:political_think/views/profile/profile.dart';
import 'package:political_think/views/maps/maps.dart';
import 'package:political_think/views/story/story_view.dart';

class ZRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter instance(
    WidgetRef ref,
  ) {
    return GoRouter(
      initialLocation: Login.location,
      navigatorKey: rootNavigatorKey,
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state, child) {
            return zPage(
              context: context,
              child: ZNavigationScaffold(
                location: state.fullPath ?? '',
                child: child,
              ),
            );
          },
          routes: [
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Feed.location,
              pageBuilder: (context, state) => zPage(
                context: context,
                child: const Feed(),
              ),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Maps.location,
              pageBuilder: (context, state) => zPage(
                context: context,
                child: const Maps(),
              ),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Games.location,
              pageBuilder: (context, state) => zPage(
                context: context,
                child: const Games(),
              ),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Messages.location,
              pageBuilder: (context, state) => zPage(
                context: context,
                child: const Messages(),
              ),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Profile.location,
              pageBuilder: (context, state) => zPage(
                context: context,
                child: const Profile(),
              ),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: "${PostView.location}/:pid",
              pageBuilder: (context, state) => zPage(
                context: context,
                child: PostView(
                  pid: state.pathParameters["pid"]!,
                ),
              ),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: "${StoryView.location}/:sid",
              pageBuilder: (context, state) => zPage(
                context: context,
                child: StoryView(
                  sid: state.pathParameters["sid"]!,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: Login.location,
          pageBuilder: (context, state) => zPage(
            context: context,
            child: const Login(),
          ),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: LoadingPage.location,
          pageBuilder: (context, state) => zPage(
            context: context,
            child: const LoadingPage(),
          ),
        ),
        // GoRoute(
        //   parentNavigatorKey: rootNavigatorKey,
        //   path: "${PostView.location}/:pid",
        //   pageBuilder: (context, state) => MaterialPage(
        //     child: PostView(
        //       pid: state.pathParameters["pid"]!,
        //     ),
        //   ),
        // ),
      ],
      refreshListenable: ref.watch(authProvider),
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final loggedIn = authState.isLoggedIn;
        final loginPath = state.fullPath?.startsWith(Login.location) ?? false;
        // final loading = authState.isLoading;
        if (state.uri.path == '/') {
          return Login.location;
        }

        if (!loggedIn) {
          return Login.location;
        }

        if (loggedIn && loginPath) {
          return Feed.location;
        }

        return null;
      },
    );
  }

  static Page<dynamic> zPage({
    required BuildContext context,
    required Widget child,
  }) {
    if (context.isWeb) {
      return NoTransitionPage(
        child: child,
      );
    }
    return CupertinoPage(
      child: child,
    );
  }
}
