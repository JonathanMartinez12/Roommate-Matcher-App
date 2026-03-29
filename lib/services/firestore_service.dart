import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/message_model.dart';
import 'auth_service.dart';
import 'matching_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FirestoreService
//
// All Firestore CRUD lives here.  Consumers (providers, screens) never import
// cloud_firestore directly — they call this service.
//
// Firestore schema:
//   users/{uid}                         — UserModel fields
//   swipes/{uid}/outgoing/{toUid}       — {direction: 'like'|'pass', createdAt}
//   matches/{matchId}                   — MatchModel fields
//   matches/{matchId}/messages/{msgId}  — MessageModel fields
//
// Match IDs are deterministic: sorted([uid1, uid2]).join('_').
// This ensures both users reference the same document.
// ═══════════════════════════════════════════════════════════════════════════

class FirestoreService {
  final FirebaseFirestore _db;
  final String currentUserId;

  FirestoreService(this.currentUserId, {FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _matches =>
      _db.collection('matches');

  // ── User methods ──────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> userStream(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Creates or fully replaces a user document (used at profile completion).
  Future<void> setUser(String userId, Map<String, dynamic> data) async {
    await _users.doc(userId).set(data, SetOptions(merge: true));
  }

  /// Partially updates an existing user document.
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _users.doc(userId).set(data, SetOptions(merge: true));
  }
  Future<void> updateLastActive(){

  return _users.doc(currentUserId).update({
    'lastActiveAt': FieldValue.serverTimestamp(),
  });
  }
  // ── Potential matches (swipe deck) ────────────────────────────────────────

  Future<List<UserModel>> getPotentialMatches({
    List<String> excludeIds = const [],
  }) async {
    // IDs already swiped by current user
    final swipedSnap = await _db
        .collection('swipes')
        .doc(currentUserId)
        .collection('outgoing')
        .get();

    final exclude = {
      currentUserId,
      ...excludeIds,
      ...swipedSnap.docs.map((d) => d.id),
    };
    // Jon Martinez - Optimization: if user has already swiped on someone, we know they're active — no need to update lastActiveAt or re-check dealbreakers until next app open.
    Future<void> updateLastActive(){
      return _users.doc(currentUserId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

    }
    // Fetch current user's profile for dealbreaker + reverse filtering
    final meDoc = await _users.doc(currentUserId).get();
    final me = meDoc.exists && meDoc.data() != null
        ? UserModel.fromMap(meDoc.data()!, currentUserId)
        : null;

    if (kDebugMode) {
      debugPrint('[SwipeDeck] currentUserId=$currentUserId');
      debugPrint('[SwipeDeck] my profile found=${me != null}, dealbreakers=${me?.dealbreakers}');
      debugPrint('[SwipeDeck] excluding ${exclude.length} id(s): $exclude');
    }

    final snap = await _users
        .where('isProfileComplete', isEqualTo: true)
        .get();

    if (kDebugMode) {
      debugPrint('[SwipeDeck] Firestore returned ${snap.docs.length} complete user(s)');
      for (final d in snap.docs) {
        debugPrint('[SwipeDeck]   uid=${d.id} name=${d.data()['name']}');
      }
    }

    final results = snap.docs
        .where((doc) => !exclude.contains(doc.id))
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where((candidate) {
          if (me == null) return true;
          if (MatchingService.violatesDealbreakers(candidate, me.dealbreakers)) {
            if (kDebugMode) debugPrint('[SwipeDeck] filtered ${candidate.name}: violates my dealbreakers');
            return false;
          }
          if (MatchingService.violatesDealbreakers(me, candidate.dealbreakers)) {
            if (kDebugMode) debugPrint('[SwipeDeck] filtered ${candidate.name}: I violate their dealbreakers');
            return false;
          }
          return true;
        })
        .toList();

    if (kDebugMode) debugPrint('[SwipeDeck] final deck size: ${results.length}');
    return results;
  }

  // ── Swipe recording ───────────────────────────────────────────────────────

  /// Writes the outgoing "like" swipe and returns true when it is mutual
  /// (i.e. the other user has already liked the current user).
  Future<bool> recordLike(String toUserId) async {
    final batch = _db.batch();

    // Outgoing swipe from current user
    batch.set(
      _db.collection('swipes').doc(currentUserId).collection('outgoing').doc(toUserId),
      {'direction': 'like', 'createdAt': FieldValue.serverTimestamp()},
    );
    // Incoming record on the target user — used for profile-view counts
    batch.set(
      _db.collection('swipes').doc(toUserId).collection('incoming').doc(currentUserId),
      {'direction': 'like', 'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();

    // Check if toUserId has already liked us by reading our own incoming
    // subcollection. We cannot read toUserId's outgoing subcollection —
    // security rules only allow a user to read their own outgoing swipes.
    final reverseDoc = await _db
        .collection('swipes')
        .doc(currentUserId)
        .collection('incoming')
        .doc(toUserId)
        .get();

    return reverseDoc.exists &&
        (reverseDoc.data()?['direction'] as String?) == 'like';
  }

  Future<void> recordPass(String toUserId) async {
    final batch = _db.batch();

    batch.set(
      _db.collection('swipes').doc(currentUserId).collection('outgoing').doc(toUserId),
      {'direction': 'pass', 'createdAt': FieldValue.serverTimestamp()},
    );
    // Also track as a profile view on the target user
    batch.set(
      _db.collection('swipes').doc(toUserId).collection('incoming').doc(currentUserId),
      {'direction': 'pass', 'createdAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  /// Creates (or no-ops if already exists) the match document for a mutual like.
  /// [compatibilityScore] is pre-calculated by the caller using [MatchingService].
  Future<MatchModel> createMatch(String toUserId,
      {int compatibilityScore = 0}) async {
    final matchId = _matchId(currentUserId, toUserId);
    final ref = _matches.doc(matchId);

    await ref.set({
      'userIds': [currentUserId, toUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'readStatus': {currentUserId: true, toUserId: false},
      'compatibilityScore': compatibilityScore,
    }, SetOptions(merge: true));

    return MatchModel(
      id: matchId,
      userIds: [currentUserId, toUserId],
      createdAt: DateTime.now(),
      readStatus: {currentUserId: true, toUserId: false},
      compatibilityScore: compatibilityScore,
    );
  }

  // ── Match methods ─────────────────────────────────────────────────────────

  Stream<List<MatchModel>> matchesStream() {
    // No orderBy on the Firestore query — lastMessageAt is absent on new
    // matches (no messages yet) which would cause index/missing-field errors.
    // Sort client-side instead: most-recently-active first.
    return _matches
        .where('userIds', arrayContains: currentUserId)
        .snapshots()
        .map((snap) {
          final matches = snap.docs
              .map((doc) => MatchModel.fromMap(doc.data(), docId: doc.id))
              .toList();
          matches.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
          return matches;
        });
  }

  Future<UserModel?> getMatchUser(String userId) => getUser(userId);

  // ── Message methods ───────────────────────────────────────────────────────

  Stream<List<MessageModel>> messagesStream(String matchId) {
    return _matches
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              return MessageModel.fromMap(doc.data()..['id'] = doc.id);
            }).toList());
  }

  Future<void> sendMessage({
    required String matchId,
    required String text,
  }) async {
    final msgRef = _matches.doc(matchId).collection('messages').doc();

    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': currentUserId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    batch.set(
      _matches.doc(matchId),
      {
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'readStatus.$currentUserId': true,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> markMessagesRead(String matchId) async {
    await _matches.doc(matchId).set(
      {'readStatus.$currentUserId': true},
      SetOptions(merge: true),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Deterministic match ID: alphabetically sorted UIDs joined by underscore.
  /// Identical result whichever user's client creates it first.
  static String _matchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Returns the deterministic match ID for the current user and [toUserId].
  String matchIdFor(String toUserId) => _matchId(currentUserId, toUserId);
}

// ── Provider ─────────────────────────────────────────────────────────────────

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  // Rebuilds whenever the Firebase auth state changes (sign-in / sign-out),
  // ensuring the service always holds the correct currentUserId.
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
  return FirestoreService(uid);
});
