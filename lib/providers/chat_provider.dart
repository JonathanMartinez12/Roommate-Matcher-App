import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final messagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, matchId) {
  return ref.watch(firestoreServiceProvider).messagesStream(matchId);
});

class ChatNotifier extends StateNotifier<bool> {
  final FirestoreService _firestore;
  final String _matchId;
  final String _senderId;

  ChatNotifier(this._firestore, this._matchId, this._senderId) : super(false);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    state = true;
    try {
      await _firestore.sendMessage(
        matchId: _matchId,
        senderId: _senderId,
        text: text,
      );
    } finally {
      state = false;
    }
  }

  Future<void> markRead() async {
    await _firestore.markMessagesRead(_matchId, _senderId);
  }
}

final chatNotifierProvider = StateNotifierProvider.family<ChatNotifier, bool, String>(
  (ref, matchId) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.valueOrNull?.uid ?? '';
    final firestore = ref.watch(firestoreServiceProvider);
    return ChatNotifier(firestore, matchId, userId);
  },
);
