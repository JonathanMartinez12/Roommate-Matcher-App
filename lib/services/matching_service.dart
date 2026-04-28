import 'package:flutter/material.dart';
import '../models/user_model.dart';

// ── Dealbreaker option definitions ────────────────────────────────────────────
//
// Each record: (key stored in Firestore, display label)
// Users pick up to 2; the swipe deck filters out anyone who violates them
// (bidirectionally — if either party has a dealbreaker the other triggers,
// neither is shown to the other).

typedef DealbreakerOption = ({String key, String label, IconData icon});

const kDealbreakerOptions = <DealbreakerOption>[
  (key: 'smoking', label: 'No smoking', icon: Icons.smoke_free),
  (key: 'drinking', label: 'No drinking', icon: Icons.no_drinks),
  (key: 'pets', label: 'No pets', icon: Icons.pets),
  (key: 'no_night_owl', label: 'No night owls', icon: Icons.nightlight_outlined),
  (key: 'no_early_bird', label: 'No early birds', icon: Icons.wb_sunny_outlined),
  (key: 'no_guests', label: 'No frequent guests', icon: Icons.group_off_outlined),
];

// ── Tag builder ───────────────────────────────────────────────────────────────
//
// Converts a Questionnaire into human-readable emoji tags for profile cards
// and the profile screen.  Returns at most [maxTags] entries.

List<String> tagsFromQuestionnaire(Questionnaire q, {int maxTags = 5}) {
  final tags = <String>[];

  // Sleep
  if (q.sleepSchedule == 'early_bird') {
    tags.add('Early bird');
  } else if (q.sleepSchedule == 'night_owl') tags.add('Night owl');
  else tags.add('Flexible sleeper');

  // Cleanliness
  if (q.cleanliness >= 5) {
    tags.add('Spotless');
  } else if (q.cleanliness == 4) tags.add('Very clean');
  else if (q.cleanliness <= 2) tags.add('Relaxed about mess');

  // Study
  if (q.studyHabits == 'library') {
    tags.add('Library studier');
  } else if (q.studyHabits == 'cafe') tags.add('Café studier');
  else if (q.studyHabits == 'at_home') tags.add('Studies at home');

  // Guests
  if (q.guestPolicy == 'frequently') {
    tags.add('Social butterfly');
  } else if (q.guestPolicy == 'never') tags.add('Prefers quiet');

  // Lifestyle
  if (!q.smoking) tags.add('Non-smoker');
  if (q.pets) tags.add('Pet-friendly');
  if (!q.drinking) tags.add('Non-drinker');

  // Temperature
  if (q.temperaturePreference == 'cool') {
    tags.add('Likes it cool');
  } else if (q.temperaturePreference == 'warm') tags.add('Likes it warm');

  return tags.take(maxTags).toList();
}

// ── MatchingService ───────────────────────────────────────────────────────────

class MatchingService {
  /// Returns a compatibility score from 0–100 based on questionnaire answers.
  /// Weights:
  ///   sleep schedule     20 %
  ///   cleanliness        20 %
  ///   noise tolerance    15 %
  ///   study habits       15 %
  ///   guest policy       10 %
  ///   substances         10 %
  ///   other (pets+temp)  10 %
  static int calculateCompatibility(Questionnaire a, Questionnaire b) {
    double score = 0;
    score += _sleepScore(a.sleepSchedule, b.sleepSchedule) * 0.20;
    score += _scaleScore(a.cleanliness, b.cleanliness, maxDiff: 4) * 0.20;
    score += _scaleScore(a.noiseTolerance, b.noiseTolerance, maxDiff: 4) * 0.15;
    score += _studyScore(a.studyHabits, b.studyHabits) * 0.15;
    score += _guestScore(a.guestPolicy, b.guestPolicy) * 0.10;
    score += _substancesScore(a, b) * 0.10;
    score += _otherScore(a, b) * 0.10;
    return score.round().clamp(0, 100);
  }

  /// Returns true if [candidate]'s lifestyle violates any of [dealbreakers].
  static bool violatesDealbreakers(
      UserModel candidate, List<String> dealbreakers) {
    if (dealbreakers.isEmpty) return false;
    final q = candidate.questionnaire;
    if (q == null) return false;
    for (final db in dealbreakers) {
      if (db == 'smoking' && q.smoking) return true;
      if (db == 'drinking' && q.drinking) return true;
      if (db == 'pets' && q.pets) return true;
      if (db == 'no_night_owl' && q.sleepSchedule == 'night_owl') return true;
      if (db == 'no_early_bird' && q.sleepSchedule == 'early_bird') return true;
      if (db == 'no_guests' && q.guestPolicy == 'frequently') return true;
    }
    return false;
  }

  static String compatibilityLabel(int score) {
    if (score >= 90) return 'Perfect Match';
    if (score >= 75) return 'Great Match';
    if (score >= 60) return 'Good Match';
    if (score >= 45) return 'Fair Match';
    return 'Low Match';
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static double _sleepScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'flexible' || b == 'flexible') return 70;
    return 20; // early_bird vs night_owl
  }

  static double _scaleScore(int a, int b, {required int maxDiff}) {
    final diff = (a - b).abs();
    return (1 - diff / maxDiff) * 100;
  }

  static double _studyScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'flexible' || b == 'flexible') return 70;
    if (a == 'at_home' || b == 'at_home') return 40;
    return 80; // library vs cafe — both quiet
  }

  static double _guestScore(String a, String b) {
    const order = {'never': 0, 'occasionally': 1, 'frequently': 2};
    final diff = (order[a]! - order[b]!).abs();
    if (diff == 0) return 100;
    if (diff == 1) return 50;
    return 10;
  }

  static double _substancesScore(Questionnaire a, Questionnaire b) {
    double score = 0;
    score += (a.smoking == b.smoking ? 100 : 0) * 0.50;
    score += (a.drinking == b.drinking ? 100 : 40) * 0.30;
    score += (a.pets == b.pets ? 100 : 20) * 0.20;
    return score;
  }

  static double _otherScore(Questionnaire a, Questionnaire b) {
    return _tempScore(a.temperaturePreference, b.temperaturePreference);
  }

  static double _tempScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'moderate' || b == 'moderate') return 60;
    return 20; // cool vs warm
  }
}
