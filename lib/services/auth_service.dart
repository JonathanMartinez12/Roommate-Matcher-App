import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'mock_data.dart';

class AuthService {
  final Ref _ref;
  AuthService(this._ref);

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = MockData.currentUser.copyWith(
      email: email,
      isProfileComplete: false,
    );
    _ref.read(authNotifierProvider.notifier).setUser(user);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = MockData.currentUser.copyWith(
      email: email,
      name: name,
      isProfileComplete: false,
    );
    _ref.read(authNotifierProvider.notifier).setUser(user);
  }

  Future<void> signOut() async {
    _ref.read(authNotifierProvider.notifier).clearUser();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> deleteAccount() async {
    _ref.read(authNotifierProvider.notifier).clearUser();
  }

  Future<void> updateEmail(String newEmail) async {
    final current = _ref.read(authNotifierProvider);
    if (current != null) {
      _ref.read(authNotifierProvider.notifier).setUser(
        current.copyWith(email: newEmail),
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {}
}

// ── Auth Notifier ────────────────────────────────────────────────────────────

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

// ── Derived providers (keep same API shape used across screens) ──────────────

/// Thin wrapper so screens can still call
/// `ref.watch(authStateProvider).valueOrNull?.uid`
final authStateProvider = Provider<AsyncValue<_AuthUser?>>((ref) {
  final user = ref.watch(authNotifierProvider);
  if (user == null) return const AsyncValue.data(null);
  return AsyncValue.data(_AuthUser(user.id));
});

final currentUserProvider = Provider<AsyncValue<UserModel?>>((ref) {
  final user = ref.watch(authNotifierProvider);
  return AsyncValue.data(user);
});

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref));

class _AuthUser {
  final String uid;
  const _AuthUser(this.uid);
}
