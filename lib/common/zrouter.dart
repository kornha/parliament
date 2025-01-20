import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/znavigation_scaffold.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/services/zprovider.dart';
import 'package:political_think/views/entity/entity_view.dart';
import 'package:political_think/views/feed/feed.dart';
import 'package:political_think/views/login/login.dart';
import 'package:political_think/views/message/message.dart';
import 'package:political_think/views/post/post_view.dart';
import 'package:political_think/views/profile/profile.dart';
import 'package:political_think/views/maps/maps.dart';
import 'package:political_think/views/search/search.dart';
import 'package:political_think/views/story/story_view.dart';

class ZRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter instance(WidgetRef ref) {
    return GoRouter(
      // initialLocation: kIsWeb ? Preview.location : Login.location,
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
              path: Search.location,
              pageBuilder: (context, state) => zPage(
                context: context,
                child: const Search(),
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
            GoRoute(
              parentNavigatorKey: _shellNavigatorKey,
              path: "${EntityView.location}/:eid",
              pageBuilder: (context, state) => zPage(
                context: context,
                child: EntityView(
                  eid: state.pathParameters["eid"]!,
                ),
              ),
            ),
          ],
        ),
        // Other routes like Login and LoadingPage without parentNavigatorKey
        GoRoute(
          path: Login.location,
          pageBuilder: (context, state) => zPage(
            context: context,
            child: const Login(),
          ),
        ),
        GoRoute(
          path: LoadingPage.location,
          pageBuilder: (context, state) => zPage(
            context: context,
            child: const LoadingPage(),
          ),
        ),
        GoRoute(
          path: "/preview",
          pageBuilder: (context, state) => zPage(
            context: context,
            child: const Feed(),
          ),
        ),
      ],
      refreshListenable: ref.watch(authProvider),
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final loggedIn = authState.isLoggedIn;
        final isOnLoginPage = state.matchedLocation == Login.location;
        final isOnFeedPage = state.matchedLocation == Feed.location;
        final isOnPreviewPage = state.matchedLocation == Preview.location;

        if (!authState.isUnknown) {
          FlutterNativeSplash.remove();
        } else {
          return null;
        }

        if (state.uri.path == '/') {
          return kIsWeb ? Preview.location : Login.location;
        }

        if (!loggedIn) {
          if (isOnLoginPage) {
            // Already on the login page and not logged in, no redirect needed.
            return null;
          }

          if (kIsWeb && isOnPreviewPage) {
            return null;
          }

          // Redirect to login with 'from' parameter.
          //final from = state.uri.toString();
          // return '${Login.location}?from=${Uri.encodeComponent(from)}';
          return Login.location;
        }

        if (loggedIn && isOnPreviewPage) {
          return Feed.location;
        }

        if (loggedIn && isOnLoginPage) {
          // Retrieve the 'from' parameter. Currenctly not set (disabled above).
          final from = state.uri.queryParameters['from'];
          if (from != null && from.isNotEmpty && from != Login.location) {
            // Redirect back to the 'from' location if it's valid and different from the login page.
            return from;
          } else {
            // No valid 'from' parameter, redirect to the default page.
            return Feed.location;
          }
        }

        // No redirect needed.
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

class CustomPathStrategy extends PathUrlStrategy {
  final String appTitle;

  CustomPathStrategy({required this.appTitle});

  @override
  void pushState(Object? state, String title, String url) {
    final pageTitle = title == "flutter" ? appTitle : title;
    super.pushState(state, pageTitle, url);
  }

  @override
  void replaceState(Object? state, String title, String url) {
    final pageTitle = title == "flutter" ? appTitle : title;
    super.pushState(state, pageTitle, url);
  }
}
