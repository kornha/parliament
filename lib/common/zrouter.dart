import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/zbottom_bar_scaffold.dart';
import 'package:political_think/common/providers/zprovider.dart';
import 'package:political_think/views/feed/feed.dart';
import 'package:political_think/views/login/login.dart';
import 'package:political_think/views/messages/messages.dart';
import 'package:political_think/views/search/search.dart';

class ZRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter instance(
    WidgetRef ref,
  ) {
    return GoRouter(
      initialLocation: Login.location,
      navigatorKey: _rootNavigatorKey,
      routes: [
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: ZBottomBarScaffold(
                location: state.fullPath ?? '',
                child: child,
              ),
            );
          },
          routes: [
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Feed.location,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Feed()),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Search.location,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Search()),
            ),
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: Messages.location,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Messages()),
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: _rootNavigatorKey,
          path: Login.location,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: Login()),
        ),
      ],
      refreshListenable: ref.watch(authProvider),
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final loggedIn = authState.isLoggedIn;
        final loginPath = state.fullPath?.startsWith(Login.location) ?? false;
        // final loading = authState.isLoading;

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
}
