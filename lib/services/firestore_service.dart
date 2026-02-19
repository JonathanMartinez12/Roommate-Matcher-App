import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  Future<void> setUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  // Get potential matches (users not yet swiped, different from current user)
  Future<List<UserModel>> getPotentialMatches(
    String currentUserId, {
    List<String> excludeIds = const [],
  }) async {
    final query = await _db
        .collection('users')
        .where('isProfileComplete', isEqualTo: true)
        .limit(20)
        .get();

    final allExclude = {...excludeIds, currentUserId};

    return query.docs
        .where((doc) => !allExclude.contains(doc.id))
        .map((doc) => UserModel.fromFirestore(doc))
        .where((u) => u.photoUrls.isNotEmpty)
        .toList();
  }

  // ── Swipes ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSwipeData(String userId) async {
    final doc = await _db.collection('swipes').doc(userId).get();
    if (!doc.exists) {
      return {'likes': [], 'passes': []};
    }
    return doc.data()!;
  }

  Future<void> recordLike(String fromUserId, String toUserId) async {
    await _db.collection('swipes').doc(fromUserId).set({
      'likes': FieldValue.arrayUnion([toUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> recordPass(String fromUserId, String toUserId) async {
    await _db.collection('swipes').doc(fromUserId).set({
      'passes': FieldValue.arrayUnion([toUserId]),
    }, SetOptions(merge: true));
  }

  Future<bool> checkMutualLike(String userId1, String userId2) async {
    final doc = await _db.collection('swipes').doc(userId2).get();
    if (!doc.exists) return false;
    final likes = List<String>.from(doc.data()?['likes'] ?? []);
    return likes.contains(userId1);
  }

  // ── Matches ────────────────────────────────────────────────────────
  Future<MatchModel> createMatch(String userId1, String userId2) async {
    final matchRef = _db.collection('matches').doc();
    final match = MatchModel(
      id: matchRef.id,
      userIds: [userId1, userId2],
      createdAt: DateTime.now(),
      readStatus: {userId1: true, userId2: false},
    );
    await matchRef.set(match.toMap());
    return match;
  }

  Stream<List<MatchModel>> matchesStream(String userId) {
    return _db
        .collection('matches')
        .where('userIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MatchModel.fromFirestore).toList());
  }

  Future<MatchModel?> getMatch(String matchId) async {
    final doc = await _db.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    return MatchModel.fromFirestore(doc);
  }

  Future<void> updateMatchLastMessage(
    String matchId,
    String message,
    String senderId,
  ) async {
    await _db.collection('matches').doc(matchId).update({
      'lastMessage': message,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'readStatus.$senderId': true,
    });
  }

  // ── Messages ───────────────────────────────────────────────────────
  Stream<List<MessageModel>> messagesStream(String matchId) {
    return _db
        .collection('messages')
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    final batch = _db.batch();

    final msgRef = _db
        .collection('messages')
        .doc(matchId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final matchRef = _db.collection('matches').doc(matchId);
    batch.update(matchRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> markMessagesRead(String matchId, String userId) async {
    await _db.collection('matches').doc(matchId).update({
      'readStatus.$userId': true,
    });
  }
}
