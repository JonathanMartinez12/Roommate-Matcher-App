import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

// ── Firebase Auth instance ─────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

// ── Reactive Firebase auth stream ──────────────────────────────────────────
//
// This StreamProvider emits a Firebase [User] whenever auth state changes:
// sign-in, sign-out, token refresh, or app restart with a persisted session.
// The rest of the app derives all auth status from this stream.

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// ═══════════════════════════════════════════════════════════════════════════
// AuthService
//
// All methods throw [FirebaseAuthException] on failure — the error codes
// (e.g. 'invalid-credential', 'email-already-in-use') are already handled
// in LoginScreen and RegisterScreen's _parseError methods.
// ═══════════════════════════════════════════════════════════════════════════

class AuthService {
  final FirebaseAuth _auth;
  final Ref _ref;

  AuthService(this._auth, this._ref);

  // ── Sign in with email + password ────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Seed minimal state first so the router can react immediately, then
    // overwrite with the full Firestore profile (so returning users skip
    // onboarding on the second notification).
    _seedNotifier(credential.user!);
    _loadFirestoreProfile(credential.user!.uid);
  }

  // ── Create account ───────────────────────────────────────────────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Persist the display name on the Firebase User record so future
    // sign-ins restore it before the Firestore document is created.
    await credential.user?.updateDisplayName(name.trim());
    _seedNotifier(credential.user!, overrideName: name.trim());
    // New users have no Firestore doc yet — create a stub so other queries
    // (e.g. getPotentialMatches) can find the record after onboarding.
    _createFirestoreStub(credential.user!, name.trim());
  }

  // ── Sign out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    // Remove this device's FCM token before losing Firestore auth.
    await _ref.read(notificationServiceProvider).clearTokenForCurrentUser();
    // Clear local profile state first so the router sees null immediately.
    _ref.read(authNotifierProvider.notifier).clearUser();
    await _auth.signOut();
  }

  // ── Password reset email ─────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Delete account ───────────────────────────────────────────────────────
  // Note: Firebase requires recent sign-in; wrap the call site in a
  // try/catch for 'requires-recent-login' and prompt re-authentication.
  Future<void> deleteAccount() async {
    _ref.read(authNotifierProvider.notifier).clearUser();
    await _auth.currentUser?.delete();
  }

  // ── Change email ─────────────────────────────────────────────────────────
  // Sends a verification link to the new address; the change takes effect
  // after the user clicks the link.  Requires recent sign-in.
  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
  }

  // ── Change password ──────────────────────────────────────────────────────
  // Requires recent sign-in.
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // ── Internal: seed the Riverpod notifier from a Firebase User object ─────
  //
  // Populates [authNotifierProvider] with a minimal UserModel immediately
  // after sign-in so the widget tree has something to render.
  // isProfileComplete is false; _loadFirestoreProfile() will overwrite it
  // for returning users.
  void _seedNotifier(User firebaseUser, {String? overrideName}) {
    _ref.read(authNotifierProvider.notifier).setUser(
      UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: overrideName ??
            firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            '',
        age: 18,
        major: '',
        university: '',
        bio: '',
        photoUrls: firebaseUser.photoURL != null
            ? [firebaseUser.photoURL!]
            : [],
        isProfileComplete: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ── Load full profile from Firestore (returning users) ───────────────────
  //
  // If a Firestore document exists, it overwrites the minimal seed so the
  // router sees isProfileComplete: true and sends the user to /home instead
  // of onboarding.  Called fire-and-forget from signIn().
  void _loadFirestoreProfile(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .then((doc) {
      if (!doc.exists || doc.data() == null) return;
      final user = UserModel.fromMap(doc.data()!, uid);
      _ref.read(authNotifierProvider.notifier).setUser(user);
    }).catchError((_) {
      // Network error — user stays on onboarding until they complete it.
    });
  }

  // ── Create Firestore stub for new sign-ups ────────────────────────────────
  //
  // Writes a minimal user document so server-side queries can discover the
  // account.  isProfileComplete is false; onboarding will update it.
  void _createFirestoreStub(User firebaseUser, String name) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .set({
      'email': firebaseUser.email ?? '',
      'name': name,
      'age': 18,
      'major': '',
      'university': '',
      'bio': '',
      'photoUrls': <String>[],
      'isProfileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((_) {});
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AuthNotifier — mutable store for the full UserModel profile
//
// This is populated in two ways:
//   • At sign-in / sign-up (_seedNotifier above) with a minimal model
//   • During onboarding (ProfileSetupScreen / QuestionnaireScreen) via
//     updateUser() as the user fills in their profile fields
//
// Phase 4 will add a third path: loading from Firestore at sign-in so that
// returning users don't need to re-run onboarding.
// ═══════════════════════════════════════════════════════════════════════════

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null);

  void setUser(UserModel user) => state = user;
  void clearUser() => state = null;

  void updateUser(UserModel Function(UserModel) updater) {
    if (state != null) state = updater(state!);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, UserModel?>((ref) => AuthNotifier());

// ═══════════════════════════════════════════════════════════════════════════
// Derived providers — same public API surface as before Phase 3
// All existing screens continue to compile without changes.
// ═══════════════════════════════════════════════════════════════════════════

/// authStateProvider
///
/// Returns an [AsyncValue<_AuthUser?>] backed by Firebase's auth stream.
/// Screens use `.valueOrNull?.uid` to get the current user's UID.
/// Now fully reactive: emits when the Firebase session is created, restored
/// from persistence, or revoked.
final authStateProvider = Provider<AsyncValue<_AuthUser?>>((ref) {
  return ref.watch(authStateChangesProvider).when(
    data: (firebaseUser) => AsyncValue.data(
      firebaseUser != null ? _AuthUser(firebaseUser.uid) : null,
    ),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// currentUserProvider
///
/// Streams the full [UserModel] from Firestore when authenticated.
/// Falls back to the local [authNotifierProvider] value while the stream
/// is loading (e.g. immediately after sign-in before the first snapshot).
/// Consumers use `.valueOrNull` to get the current user.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(authStateChangesProvider).valueOrNull;
  if (firebaseUser == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  });
});

/// authServiceProvider — single instance wired to FirebaseAuth
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthProvider), ref),
);

// ── Internal UID wrapper (keeps the public API surface unchanged) ──────────
class _AuthUser {
  final String uid;
  const _AuthUser(this.uid);
}
