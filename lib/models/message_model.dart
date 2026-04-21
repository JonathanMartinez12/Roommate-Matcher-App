import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      createdAt: _toDateTime(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
