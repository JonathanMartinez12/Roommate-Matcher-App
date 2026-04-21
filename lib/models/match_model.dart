import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final List<String> userIds;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, bool> readStatus;
  final int compatibilityScore;

  const MatchModel({
    required this.id,
    required this.userIds,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.readStatus = const {},
    this.compatibilityScore = 0,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MatchModel(
      id: docId ?? map['id'] ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
      createdAt: _toDateTime(map['createdAt']),
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: map['lastMessageAt'] != null
          ? _toDateTime(map['lastMessageAt'])
          : null,
      readStatus: Map<String, bool>.from(map['readStatus'] ?? {}),
      compatibilityScore: map['compatibilityScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userIds': userIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'readStatus': readStatus,
      'compatibilityScore': compatibilityScore,
    };
  }

  String otherUserId(String currentUserId) {
    return userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  bool isUnread(String userId) => readStatus[userId] == false;

  MatchModel copyWith({
    String? id,
    List<String>? userIds,
    DateTime? createdAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    Map<String, bool>? readStatus,
    int? compatibilityScore,
  }) {
    return MatchModel(
      id: id ?? this.id,
      userIds: userIds ?? this.userIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      readStatus: readStatus ?? this.readStatus,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
    );
  }
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
