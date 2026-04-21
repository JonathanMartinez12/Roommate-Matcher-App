import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, matchId) {
  return ref.watch(firestoreServiceProvider).messagesStream(matchId);
});

class ChatNotifier extends StateNotifier<bool> {
  final FirestoreService _service;
  final String _matchId;

  ChatNotifier(this._service, this._matchId) : super(false);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    state = true;
    try {
      await _service.sendMessage(matchId: _matchId, text: text);
    } finally {
      state = false;
    }
  }

  Future<void> markRead() async {
    await _service.markMessagesRead(_matchId);
  }
}

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, bool, String>(
  (ref, matchId) {
    final service = ref.watch(firestoreServiceProvider);
    return ChatNotifier(service, matchId);
  },
);
