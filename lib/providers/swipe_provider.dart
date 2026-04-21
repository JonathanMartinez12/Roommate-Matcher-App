import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/matching_service.dart';
import 'auth_provider.dart';

class SwipeNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final FirestoreService _service;
  final String _currentUserId;
  final UserModel? _currentUser;
  final List<String> _swipedIds = [];

  SwipeNotifier(this._service, this._currentUserId, this._currentUser)
      : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    try {
      final profiles = await _service.getPotentialMatches(
        excludeIds: _swipedIds,
      );
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Likes [toUserId]. Returns true when a mutual match is created.
  Future<bool> like(String toUserId) async {
    // Capture the liked user's profile before removing from state.
    final likedUser = state.valueOrNull
        ?.where((p) => p.id == toUserId)
        .firstOrNull;

    _swipedIds.add(toUserId);
    _removeProfile(toUserId);

    final isMatch = await _service.recordLike(toUserId);
    if (isMatch) {
      // Calculate compatibility score from both questionnaires.
      int score = 0;
      final myQ = _currentUser?.questionnaire;
      final theirQ = likedUser?.questionnaire;
      if (myQ != null && theirQ != null) {
        score = MatchingService.calculateCompatibility(myQ, theirQ);
      }
      await _service.createMatch(toUserId, compatibilityScore: score);
      return true;
    }
    return false;
  }

  Future<void> pass(String toUserId) async {
    _swipedIds.add(toUserId);
    await _service.recordPass(toUserId);
    _removeProfile(toUserId);
  }

  void _removeProfile(String userId) {
    state.whenData((profiles) {
      state =
          AsyncValue.data(profiles.where((p) => p.id != userId).toList());
    });
  }
}

final swipeProvider =
    StateNotifierProvider<SwipeNotifier, AsyncValue<List<UserModel>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid ?? '';
  final service = ref.watch(firestoreServiceProvider);
  // Use ref.read (not ref.watch) so that profile-field updates from Firestore
  // don't tear down and rebuild the swipe deck mid-session.
  // The notifier only recreates when auth state or userId changes.
  final currentUser = ref.read(currentUserProvider).valueOrNull;
  return SwipeNotifier(service, userId, currentUser);
});

/// Returns the deterministic Firestore match ID for the current user and [otherUserId].
final matchIdProvider = Provider.family<String, String>((ref, otherUserId) {
  final service = ref.watch(firestoreServiceProvider);
  return service.matchIdFor(otherUserId);
});
