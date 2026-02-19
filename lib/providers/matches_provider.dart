import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final matchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).matchesStream(userId);
});

final matchUserProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  return ref.watch(firestoreServiceProvider).getUser(userId);
});
