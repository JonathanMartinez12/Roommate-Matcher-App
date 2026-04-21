import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/profile_setup_screen.dart';
import '../../features/onboarding/screens/photo_upload_screen.dart';
import '../../features/onboarding/screens/questionnaire_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/edit_preferences_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../home/home_screen.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

// ── Router change notifier ─────────────────────────────────────────────────
//
// Listens to two independent state sources and notifies GoRouter to re-run
// its redirect logic whenever either changes:
//
//   1. authStateChangesProvider — Firebase's auth stream (sign-in / sign-out)
//   2. currentUserProvider      — live Firestore profile (isProfileComplete flag)
//
// currentUserProvider is the authoritative source so that returning users who
// already have isProfileComplete=true in Firestore are sent straight to /home
// without needing to go through the in-memory authNotifierProvider path.

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    // React when Firebase auth state changes (login / logout / session restore)
    ref.listen<AsyncValue<User?>>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );
    // React when the Firestore profile loads or isProfileComplete changes
    ref.listen<AsyncValue<UserModel?>>(
      currentUserProvider,
      (_, __) => notifyListeners(),
    );
  }
}

// ── Router provider ────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      // ── Auth state from Firebase stream ─────────────────────────────────
      final firebaseUser = ref.read(authStateChangesProvider).valueOrNull;
      final isAuthenticated = firebaseUser != null;

      // ── Hold while Firestore profile is loading ──────────────────────────
      // Prevents briefly showing onboarding for returning users whose profile
      // hasn't arrived from Firestore yet (isProfileComplete would read false).
      final currentUserAsync = ref.read(currentUserProvider);
      if (isAuthenticated && currentUserAsync.isLoading) return null;

      // ── Profile state — prefer live Firestore value, fall back to notifier
      // currentUserProvider is the Firestore stream (authoritative).
      // authNotifierProvider covers the brief gap between sign-in and the
      // first Firestore snapshot (seeded by AuthService._loadFirestoreProfile).
      final profileUser = ref.read(currentUserProvider).valueOrNull
          ?? ref.read(authNotifierProvider);
      final isProfileComplete = profileUser?.isProfileComplete ?? false;

      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isAuthRoute = loc == '/login' || loc == '/register';
      final isOnboardingRoute = loc.startsWith('/onboarding');

      // Splash handles its own navigation — never redirect away from it
      if (isSplash) return null;

      // Unauthenticated users may only access auth screens
      if (!isAuthenticated && !isAuthRoute) return '/login';

      if (isAuthenticated) {
        if (!isProfileComplete) {
          // Needs onboarding — keep them there
          if (!isOnboardingRoute) return '/onboarding/profile';
        } else {
          // Profile complete — push away from auth/onboarding screens
          if (isAuthRoute || isOnboardingRoute) return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
          final matchedUserName =
              state.uri.queryParameters['name'] ?? 'Match';
          final matchedUserPhoto =
              state.uri.queryParameters['photo'] ?? '';
          final matchedUserId =
              state.uri.queryParameters['userId'] ?? '';
          return ChatRoomScreen(
            matchId: matchId,
            matchedUserName: matchedUserName,
            matchedUserPhoto: matchedUserPhoto,
            matchedUserId: matchedUserId,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/preferences',
        builder: (context, state) => const EditPreferencesScreen(),
      ),
    ],
  );
});
