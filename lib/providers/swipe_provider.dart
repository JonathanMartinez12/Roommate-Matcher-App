import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class SwipeNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final MockDataService _mock;
  final String _currentUserId;
  final List<String> _swipedIds = [];

  SwipeNotifier(this._mock, this._currentUserId)
      : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    try {
      final profiles = await _mock.getPotentialMatches(
        excludeIds: _swipedIds,
      );
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> like(String toUserId) async {
    _swipedIds.add(toUserId);
    _removeProfile(toUserId);
    final isMatch = await _mock.recordLike(toUserId);
    if (isMatch) {
      _mock.createMatch(toUserId);
      return true;
    }
    return false;
  }

  Future<void> pass(String toUserId) async {
    _swipedIds.add(toUserId);
    await _mock.recordPass(toUserId);
    _removeProfile(toUserId);
  }

  void _removeProfile(String userId) {
    state.whenData((profiles) {
      state = AsyncValue.data(profiles.where((p) => p.id != userId).toList());
    });
  }

  MatchModel? getLatestMatch() => _mock.createMatch(_currentUserId);
}

final swipeProvider =
    StateNotifierProvider<SwipeNotifier, AsyncValue<List<UserModel>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid ?? '';
  final mock = ref.watch(firestoreServiceProvider);
  return SwipeNotifier(mock, userId);
});
