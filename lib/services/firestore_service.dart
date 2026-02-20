import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import 'mock_data.dart';

/// In-memory mock of what was previously Firestore.
/// All data resets when the app restarts — that's fine for local dev.
class MockDataService {
  final String currentUserId;

  MockDataService(this.currentUserId);

  // ── User methods ────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String userId) async {
    return MockData.getUserById(userId);
  }

  Stream<UserModel?> userStream(String userId) {
    return Stream.value(MockData.getUserById(userId));
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {}
  Future<void> setUser(String userId, Map<String, dynamic> data) async {}

  // ── Swipe methods ───────────────────────────────────────────────────────
  final List<String> _likedIds = [];
  final List<String> _passedIds = [];
  final List<MatchModel> _runtimeMatches = [];

  Future<List<UserModel>> getPotentialMatches({
    List<String> excludeIds = const [],
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final allExclude = {...excludeIds, currentUserId, ..._likedIds, ..._passedIds};
    return MockData.profiles
        .where((p) => !allExclude.contains(p.id))
        .toList();
  }

  Future<bool> recordLike(String toUserId) async {
    _likedIds.add(toUserId);
    // 1-in-3 chance of a match for demo purposes
    return _likedIds.length % 3 == 0;
  }

  Future<void> recordPass(String toUserId) async {
    _passedIds.add(toUserId);
  }

  MatchModel createMatch(String toUserId) {
    final match = MatchModel(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      userIds: [currentUserId, toUserId],
      createdAt: DateTime.now(),
      readStatus: {currentUserId: true, toUserId: false},
    );
    _runtimeMatches.add(match);
    return match;
  }

  // ── Match methods ───────────────────────────────────────────────────────
  Stream<List<MatchModel>> matchesStream() {
    final seeded = MockData.matchesFor(currentUserId);
    final all = [...seeded, ..._runtimeMatches];
    return Stream.value(all);
  }

  Future<UserModel?> getMatchUser(String userId) async {
    return MockData.getUserById(userId);
  }

  // ── Message methods ─────────────────────────────────────────────────────
  final Map<String, List<MessageModel>> _messages = {};

  Stream<List<MessageModel>> messagesStream(String matchId) {
    final seeded = MockData.messagesFor(matchId, currentUserId);
    final runtime = _messages[matchId] ?? [];
    final all = [...seeded, ...runtime];
    return Stream.value(all);
  }

  Future<void> sendMessage({
    required String matchId,
    required String text,
  }) async {
    final msg = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      text: text.trim(),
      createdAt: DateTime.now(),
      isRead: false,
    );
    _messages.putIfAbsent(matchId, () => []).add(msg);
  }

  Future<void> markMessagesRead(String matchId) async {}
}

final firestoreServiceProvider = Provider<MockDataService>((ref) {
  // auth_provider.dart exports authNotifierProvider
  // We import it indirectly via the provider graph
  return MockDataService(kCurrentUserId);
});
