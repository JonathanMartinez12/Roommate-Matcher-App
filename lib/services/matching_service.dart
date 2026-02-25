import '../models/user_model.dart';

class MatchingService {
  /// Returns a compatibility score from 0-100 based on questionnaire.
  /// Weights:
  ///   sleep schedule     20%
  ///   cleanliness        20%
  ///   noise tolerance    15%
  ///   study habits       15%
  ///   guest policy       10%
  ///   substances         10%
  ///   other (pets+temp)  10%
  static int calculateCompatibility(Questionnaire a, Questionnaire b) {
    double score = 0;

    // Sleep schedule (20%)
    score += _sleepScore(a.sleepSchedule, b.sleepSchedule) * 0.20;

    // Cleanliness (20%)
    score += _scaleScore(a.cleanliness, b.cleanliness, maxDiff: 4) * 0.20;

    // Noise tolerance (15%)
    score += _scaleScore(a.noiseTolerance, b.noiseTolerance, maxDiff: 4) * 0.15;

    // Study habits (15%)
    score += _studyScore(a.studyHabits, b.studyHabits) * 0.15;

    // Guest policy (10%)
    score += _guestScore(a.guestPolicy, b.guestPolicy) * 0.10;

    // Substances: smoking + drinking (10%)
    score += _substancesScore(a, b) * 0.10;

    // Other: pets + temperature (10%)
    score += _otherScore(a, b) * 0.10;

    return score.round().clamp(0, 100);
  }

  static double _sleepScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'flexible' || b == 'flexible') return 70;
    // early_bird vs night_owl
    return 20;
  }

  static double _scaleScore(int a, int b, {required int maxDiff}) {
    final diff = (a - b).abs();
    return (1 - diff / maxDiff) * 100;
  }

  static double _studyScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'flexible' || b == 'flexible') return 70;
    // at_home vs others matters (noise)
    if (a == 'at_home' || b == 'at_home') return 40;
    return 80; // library vs cafe -- similar
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
    // Smoking hard match (60% of substance weight)
    score += (a.smoking == b.smoking ? 100 : 0) * 0.6;
    // Drinking soft match (40% of substance weight)
    score += (a.drinking == b.drinking ? 100 : 30) * 0.4;
    return score;
  }

  static double _otherScore(Questionnaire a, Questionnaire b) {
    double score = 0;
    // Pets (50% of other)
    score += (a.pets == b.pets ? 100 : 20) * 0.5;
    // Temperature (50% of other)
    score += _tempScore(a.temperaturePreference, b.temperaturePreference) * 0.5;
    return score;
  }

  static double _tempScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'moderate' || b == 'moderate') return 60;
    return 20; // cool vs warm
  }

  static String compatibilityLabel(int score) {
    if (score >= 90) return 'Perfect Match';
    if (score >= 75) return 'Great Match';
    if (score >= 60) return 'Good Match';
    if (score >= 45) return 'Fair Match';
    return 'Low Match';
  }
}
