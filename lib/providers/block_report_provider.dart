import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final blockedUsersProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).blockedUsersStream();
});
