import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, bool> readStatus;

  const MatchModel({
    required this.id,
    required this.userIds,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.readStatus = const {},
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      readStatus: Map<String, bool>.from(data['readStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userIds': userIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'readStatus': readStatus,
    };
  }

  String otherUserId(String currentUserId) {
    return userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  bool isUnread(String userId) {
    return readStatus[userId] == false;
  }

  MatchModel copyWith({
    String? id,
    List<String>? userIds,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, bool>? readStatus,
  }) {
    return MatchModel(
      id: id ?? this.id,
      userIds: userIds ?? this.userIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      readStatus: readStatus ?? this.readStatus,
    );
  }
}
