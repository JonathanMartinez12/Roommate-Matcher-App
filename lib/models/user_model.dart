import 'package:cloud_firestore/cloud_firestore.dart';

class Questionnaire {
  final String sleepSchedule; // 'early_bird', 'night_owl', 'flexible'
  final int cleanliness; // 1-5
  final int noiseTolerance; // 1-5
  final String studyHabits; // 'at_home', 'library', 'cafe', 'flexible'
  final String guestPolicy; // 'never', 'occasionally', 'frequently'
  final bool smoking;
  final bool drinking;
  final bool pets;
  final String temperaturePreference; // 'cool', 'moderate', 'warm'

  const Questionnaire({
    required this.sleepSchedule,
    required this.cleanliness,
    required this.noiseTolerance,
    required this.studyHabits,
    required this.guestPolicy,
    required this.smoking,
    required this.drinking,
    required this.pets,
    required this.temperaturePreference,
  });

  factory Questionnaire.fromMap(Map<String, dynamic> map) {
    return Questionnaire(
      sleepSchedule: map['sleepSchedule'] ?? 'flexible',
      cleanliness: map['cleanliness'] ?? 3,
      noiseTolerance: map['noiseTolerance'] ?? 3,
      studyHabits: map['studyHabits'] ?? 'flexible',
      guestPolicy: map['guestPolicy'] ?? 'occasionally',
      smoking: map['smoking'] ?? false,
      drinking: map['drinking'] ?? false,
      pets: map['pets'] ?? false,
      temperaturePreference: map['temperaturePreference'] ?? 'moderate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sleepSchedule': sleepSchedule,
      'cleanliness': cleanliness,
      'noiseTolerance': noiseTolerance,
      'studyHabits': studyHabits,
      'guestPolicy': guestPolicy,
      'smoking': smoking,
      'drinking': drinking,
      'pets': pets,
      'temperaturePreference': temperaturePreference,
    };
  }

  Questionnaire copyWith({
    String? sleepSchedule,
    int? cleanliness,
    int? noiseTolerance,
    String? studyHabits,
    String? guestPolicy,
    bool? smoking,
    bool? drinking,
    bool? pets,
    String? temperaturePreference,
  }) {
    return Questionnaire(
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      cleanliness: cleanliness ?? this.cleanliness,
      noiseTolerance: noiseTolerance ?? this.noiseTolerance,
      studyHabits: studyHabits ?? this.studyHabits,
      guestPolicy: guestPolicy ?? this.guestPolicy,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      pets: pets ?? this.pets,
      temperaturePreference: temperaturePreference ?? this.temperaturePreference,
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final String major;
  final String university;
  final String bio;
  final List<String> photoUrls;
  final Questionnaire? questionnaire;
  final bool isProfileComplete;
  final DateTime createdAt;

  /// Up to 2 lifestyle dealbreakers — users whose profile violates any of
  /// these will never appear in this user's swipe deck (and vice versa).
  /// Valid values: 'smoking', 'drinking', 'pets',
  ///               'no_night_owl', 'no_early_bird', 'no_guests'
  final List<String> dealbreakers;
  final DateTime?  lastActiveAt;
  final List<String> blockedUsers;
  final List<String> fcmTokens;
  final bool notifyOnMatch;
  final bool notifyOnMessage;
  /// When non-null, the recipient is actively viewing this chat and should
  /// not receive push notifications for incoming messages in it.
  final String? activeChatId;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.major,
    required this.university,
    required this.bio,
    required this.photoUrls,
    this.questionnaire,
    required this.isProfileComplete,
    required this.createdAt,
    this.dealbreakers = const [],
    this.lastActiveAt,
    this.blockedUsers = const [],
    this.fcmTokens = const [],
    this.notifyOnMatch = true,
    this.notifyOnMessage = true,
    this.activeChatId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 18,
      major: map['major'] ?? '',
      university: map['university'] ?? '',
      bio: map['bio'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      questionnaire: map['questionnaire'] != null
          ? Questionnaire.fromMap(Map<String, dynamic>.from(map['questionnaire']))
          : null,
      isProfileComplete: map['isProfileComplete'] ?? false,
      createdAt: _toDateTime(map['createdAt']),
      dealbreakers: List<String>.from(map['dealbreakers'] ?? []),
      lastActiveAt: map['lastActiveAt'] != null ? _toDateTime(map['lastActiveAt']) : null,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      notifyOnMatch: map['notifyOnMatch'] ?? true,
      notifyOnMessage: map['notifyOnMessage'] ?? true,
      activeChatId: map['activeChatId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'major': major,
      'university': university,
      'bio': bio,
      'photoUrls': photoUrls,
      'questionnaire': questionnaire?.toMap(),
      'isProfileComplete': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'dealbreakers': dealbreakers,
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'blockedUsers': blockedUsers,
      'fcmTokens': fcmTokens,
      'notifyOnMatch': notifyOnMatch,
      'notifyOnMessage': notifyOnMessage,
      'activeChatId': activeChatId,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? major,
    String? university,
    String? bio,
    List<String>? photoUrls,
    Questionnaire? questionnaire,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    List<String>? dealbreakers,
    List<String>? blockedUsers,
    List<String>? fcmTokens,
    bool? notifyOnMatch,
    bool? notifyOnMessage,
    String? activeChatId,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      major: major ?? this.major,
      university: university ?? this.university,
      bio: bio ?? this.bio,
      photoUrls: photoUrls ?? this.photoUrls,
      questionnaire: questionnaire ?? this.questionnaire,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      dealbreakers: dealbreakers ?? this.dealbreakers,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      notifyOnMatch: notifyOnMatch ?? this.notifyOnMatch,
      notifyOnMessage: notifyOnMessage ?? this.notifyOnMessage,
      activeChatId: activeChatId ?? this.activeChatId,
    );
  }

  String get firstName => name.split(' ').first;
  String get primaryPhoto => photoUrls.isNotEmpty ? photoUrls.first : '';
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
