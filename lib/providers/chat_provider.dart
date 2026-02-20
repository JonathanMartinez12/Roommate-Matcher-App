import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, matchId) {
  return ref.watch(firestoreServiceProvider).messagesStream(matchId);
});

class ChatNotifier extends StateNotifier<bool> {
  final MockDataService _mock;
  final String _matchId;

  ChatNotifier(this._mock, this._matchId) : super(false);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    state = true;
    try {
      await _mock.sendMessage(matchId: _matchId, text: text);
    } finally {
      state = false;
    }
  }

  Future<void> markRead() async {
    await _mock.markMessagesRead(_matchId);
  }
}

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, bool, String>(
  (ref, matchId) {
    final mock = ref.watch(firestoreServiceProvider);
    return ChatNotifier(mock, matchId);
  },
);
