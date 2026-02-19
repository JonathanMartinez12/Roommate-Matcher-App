import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/matching_service.dart';
import 'auth_provider.dart';

class SwipeNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final FirestoreService _firestore;
  final String _currentUserId;

  SwipeNotifier(this._firestore, this._currentUserId)
      : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  List<String> _swipedIds = [];

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    try {
      final swipeData = await _firestore.getSwipeData(_currentUserId);
      _swipedIds = [
        ...List<String>.from(swipeData['likes'] ?? []),
        ...List<String>.from(swipeData['passes'] ?? []),
      ];

      final profiles = await _firestore.getPotentialMatches(
        _currentUserId,
        excludeIds: _swipedIds,
      );
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> like(String toUserId) async {
    await _firestore.recordLike(_currentUserId, toUserId);
    _removeProfile(toUserId);

    // Check for mutual like
    final isMutual = await _firestore.checkMutualLike(_currentUserId, toUserId);
    if (isMutual) {
      await _firestore.createMatch(_currentUserId, toUserId);
      return true; // it's a match!
    }
    return false;
  }

  Future<void> pass(String toUserId) async {
    await _firestore.recordPass(_currentUserId, toUserId);
    _removeProfile(toUserId);
  }

  void _removeProfile(String userId) {
    state.whenData((profiles) {
      state = AsyncValue.data(profiles.where((p) => p.id != userId).toList());
    });
  }

  int getCompatibility(UserModel other) {
    final current = state.valueOrNull?.firstWhere(
      (u) => u.id == other.id,
      orElse: () => other,
    );
    if (current?.questionnaire == null) return 0;
    // We need current user's questionnaire -- handled at widget level
    return 0;
  }
}

final swipeProvider = StateNotifierProvider<SwipeNotifier, AsyncValue<List<UserModel>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid ?? '';
  final firestore = ref.watch(firestoreServiceProvider);
  return SwipeNotifier(firestore, userId);
});
