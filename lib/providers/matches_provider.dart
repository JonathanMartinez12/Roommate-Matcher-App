import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'block_report_provider.dart';

final matchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  if (userId == null) return Stream.value([]);
  final blockedUsers = ref.watch(blockedUsersProvider).valueOrNull ?? [];
  return ref.watch(firestoreServiceProvider).matchesStream(blockedUserIds: blockedUsers);
});

final matchUserProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  return ref.watch(firestoreServiceProvider).getUser(userId);
});

// ── Profile views provider ────────────────────────────────────────────────────
//
// Streams the number of times other users have swiped on the current user
// (both likes and passes count as a profile view).
// Returns a record with total views and views in the last 7 days.

typedef ProfileViewStats = ({int total, int thisWeek});

final profileViewsProvider = StreamProvider<ProfileViewStats>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value((total: 0, thisWeek: 0));

  final weekAgo = DateTime.now().subtract(const Duration(days: 7));

  return FirebaseFirestore.instance
      .collection('swipes')
      .doc(uid)
      .collection('incoming')
      .snapshots()
      .map((snap) {
    final total = snap.docs.length;
    final thisWeek = snap.docs.where((doc) {
      final ts = doc.data()['createdAt'];
      if (ts == null) return false;
      final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
      return dt.isAfter(weekAgo);
    }).length;
    return (total: total, thisWeek: thisWeek);
  });
});
