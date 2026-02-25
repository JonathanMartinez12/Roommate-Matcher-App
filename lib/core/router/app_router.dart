import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/profile_setup_screen.dart';
import '../../features/onboarding/screens/photo_upload_screen.dart';
import '../../features/onboarding/screens/questionnaire_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../home/home_screen.dart';

/// Bridges Riverpod auth state into a ChangeNotifier so GoRouter
/// can re-run redirects without recreating the router on every state change.
/// Uses .select() so only routing-relevant changes (login/logout, profile
/// completion) trigger a re-evaluation — not every profile field update.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<(String?, bool?)>(
      authNotifierProvider.select((u) => (u?.id, u?.isProfileComplete)),
      (_, __) => notifyListeners(),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(authNotifierProvider);
      final isAuthenticated = user != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isOnboardingRoute = loc.startsWith('/onboarding');

      if (!isAuthenticated && !isAuthRoute) return '/login';

      if (isAuthenticated && user != null) {
        if (!user.isProfileComplete) {
          if (!isOnboardingRoute) return '/onboarding/profile';
        } else {
          if (isAuthRoute || isOnboardingRoute) return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/photos',
        builder: (context, state) => const PhotoUploadScreen(),
      ),
      GoRoute(
        path: '/onboarding/questionnaire',
        builder: (context, state) => const QuestionnaireScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final matchedUserName = state.uri.queryParameters['name'] ?? 'Match';
          final matchedUserPhoto = state.uri.queryParameters['photo'] ?? '';
          return ChatRoomScreen(
            matchId: matchId,
            matchedUserName: matchedUserName,
            matchedUserPhoto: matchedUserPhoto,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
