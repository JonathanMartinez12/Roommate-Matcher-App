class Questionnaire {
  final String sleepSchedule; // 'early_bird', 'night_owl', 'flexible'
  final int cleanliness; // 1-5
  final int noiseTolerance; // 1-5 (kept for backward compat, defaults to 3)
  final String fridayNight; // 'studying', 'lowkey', 'party'
  final String guestsFrequency; // 'rarely', 'monthly', 'weekends', 'always'
  final String overnightGuests; // 'prefer_not', 'heads_up', 'fine'
  final String noiseLevel; // 'quiet', 'background', 'lively'
  final String morningRoutine; // 'quick', 'moderate', 'long'
  final String kitchenHabits; // 'cook', 'reheat', 'eat_out'
  final String sharingComfort; // 'separate', 'some', 'share'
  final String rentBudget; // 'under_600', '600_900', '900_1200', '1200_plus'
  final String homeFrequency; // 'rarely', 'sometimes', 'often'
  final bool smoking;
  final bool drinking;
  final bool pets;

  const Questionnaire({
    required this.sleepSchedule,
    required this.cleanliness,
    this.noiseTolerance = 3,
    required this.fridayNight,
    required this.guestsFrequency,
    required this.overnightGuests,
    required this.noiseLevel,
    required this.morningRoutine,
    required this.kitchenHabits,
    required this.sharingComfort,
    required this.rentBudget,
    required this.homeFrequency,
    required this.smoking,
    required this.drinking,
    required this.pets,
  });

  factory Questionnaire.fromMap(Map<String, dynamic> map) {
    return Questionnaire(
      sleepSchedule: map['sleepSchedule'] ?? 'flexible',
      cleanliness: map['cleanliness'] ?? 3,
      noiseTolerance: map['noiseTolerance'] ?? 3,
      fridayNight: map['fridayNight'] ?? 'lowkey',
      guestsFrequency: map['guestsFrequency'] ?? 'monthly',
      overnightGuests: map['overnightGuests'] ?? 'heads_up',
      noiseLevel: map['noiseLevel'] ?? 'background',
      morningRoutine: map['morningRoutine'] ?? 'moderate',
      kitchenHabits: map['kitchenHabits'] ?? 'reheat',
      sharingComfort: map['sharingComfort'] ?? 'some',
      rentBudget: map['rentBudget'] ?? '600_900',
      homeFrequency: map['homeFrequency'] ?? 'sometimes',
      smoking: map['smoking'] ?? false,
      drinking: map['drinking'] ?? false,
      pets: map['pets'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sleepSchedule': sleepSchedule,
      'cleanliness': cleanliness,
      'noiseTolerance': noiseTolerance,
      'fridayNight': fridayNight,
      'guestsFrequency': guestsFrequency,
      'overnightGuests': overnightGuests,
      'noiseLevel': noiseLevel,
      'morningRoutine': morningRoutine,
      'kitchenHabits': kitchenHabits,
      'sharingComfort': sharingComfort,
      'rentBudget': rentBudget,
      'homeFrequency': homeFrequency,
      'smoking': smoking,
      'drinking': drinking,
      'pets': pets,
    };
  }

  Questionnaire copyWith({
    String? sleepSchedule,
    int? cleanliness,
    int? noiseTolerance,
    String? fridayNight,
    String? guestsFrequency,
    String? overnightGuests,
    String? noiseLevel,
    String? morningRoutine,
    String? kitchenHabits,
    String? sharingComfort,
    String? rentBudget,
    String? homeFrequency,
    bool? smoking,
    bool? drinking,
    bool? pets,
  }) {
    return Questionnaire(
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      cleanliness: cleanliness ?? this.cleanliness,
      noiseTolerance: noiseTolerance ?? this.noiseTolerance,
      fridayNight: fridayNight ?? this.fridayNight,
      guestsFrequency: guestsFrequency ?? this.guestsFrequency,
      overnightGuests: overnightGuests ?? this.overnightGuests,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      morningRoutine: morningRoutine ?? this.morningRoutine,
      kitchenHabits: kitchenHabits ?? this.kitchenHabits,
      sharingComfort: sharingComfort ?? this.sharingComfort,
      rentBudget: rentBudget ?? this.rentBudget,
      homeFrequency: homeFrequency ?? this.homeFrequency,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      pets: pets ?? this.pets,
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
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
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
    );
  }

  String get firstName => name.split(' ').first;
  String get primaryPhoto => photoUrls.isNotEmpty ? photoUrls.first : '';
}
