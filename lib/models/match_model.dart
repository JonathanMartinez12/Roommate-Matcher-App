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

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'] ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.parse(map['lastMessageAt'])
          : null,
      readStatus: Map<String, bool>.from(map['readStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userIds': userIds,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
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
