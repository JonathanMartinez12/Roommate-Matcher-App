import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart' show Questionnaire;
import 'matching_service.dart';
import 'mock_data.dart';

/// Writes the hardcoded [MockData] profiles, matches, and messages to Firestore
/// so matching and chat can be tested end-to-end.
///
/// Safe to call multiple times — uses `set(merge: true)` so existing docs
/// won't be destroyed.
class SeedService {
  final FirebaseFirestore _db;
  final String currentUserId;

  SeedService(this.currentUserId, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> seedAll() async {
    await _seedUsers();
    await _seedMatches();
    await _seedMessages();
    if (kDebugMode) debugPrint('[Seed] Done — seeded users, matches & messages');
  }

  Future<void> _seedUsers() async {
    final batch = _db.batch();
    for (final user in MockData.profiles) {
      batch.set(
        _db.collection('users').doc(user.id),
        user.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    if (kDebugMode) {
      debugPrint('[Seed] Wrote ${MockData.profiles.length} test users');
    }
  }

  Future<void> _seedMatches() async {
    if (currentUserId.isEmpty) return;

    // Read the current user's questionnaire to calculate real scores
    final meDoc = await _db.collection('users').doc(currentUserId).get();
    final meQ = meDoc.data()?['questionnaire'] != null
        ? Questionnaire.fromMap(Map<String, dynamic>.from(meDoc.data()!['questionnaire']))
        : null;

    final matches = MockData.matchesFor(currentUserId);
    final batch = _db.batch();
    for (final match in matches) {
      final otherUid = match.otherUserId(currentUserId);
      final sorted = [currentUserId, otherUid]..sort();
      final matchId = '${sorted[0]}_${sorted[1]}';

      // Calculate real compatibility if possible
      final otherUser = MockData.getUserById(otherUid);
      int score = match.compatibilityScore;
      if (meQ != null && otherUser?.questionnaire != null) {
        score = MatchingService.calculateCompatibility(meQ, otherUser!.questionnaire!);
      }

      batch.set(
        _db.collection('matches').doc(matchId),
        {
          'userIds': [currentUserId, otherUid],
          'createdAt': Timestamp.fromDate(match.createdAt),
          'lastMessage': match.lastMessage,
          'lastMessageAt': match.lastMessageAt != null
              ? Timestamp.fromDate(match.lastMessageAt!)
              : null,
          'readStatus': match.readStatus,
          'compatibilityScore': score,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();

    // Also record the mutual swipes so matched users don't reappear in the deck
    final swipeBatch = _db.batch();
    for (final match in matches) {
      final otherUid = match.otherUserId(currentUserId);
      swipeBatch.set(
        _db.collection('swipes').doc(currentUserId).collection('outgoing').doc(otherUid),
        {'direction': 'like', 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      swipeBatch.set(
        _db.collection('swipes').doc(otherUid).collection('incoming').doc(currentUserId),
        {'direction': 'like', 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    await swipeBatch.commit();

    if (kDebugMode) debugPrint('[Seed] Wrote ${matches.length} test matches + swipe records');
  }

  Future<void> _seedMessages() async {
    if (currentUserId.isEmpty) return;
    // Seed messages for the first match (with user_1)
    final sorted = [currentUserId, 'user_1']..sort();
    final matchId = '${sorted[0]}_${sorted[1]}';

    final messages = MockData.messagesFor('match_1', currentUserId);
    final batch = _db.batch();
    for (final msg in messages) {
      batch.set(
        _db.collection('matches').doc(matchId).collection('messages').doc(msg.id),
        {
          'senderId': msg.senderId,
          'text': msg.text,
          'createdAt': Timestamp.fromDate(msg.createdAt),
          'isRead': msg.isRead,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    if (kDebugMode) debugPrint('[Seed] Wrote ${messages.length} test messages');
  }
}
