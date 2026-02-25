import '../models/user_model.dart';

class MatchingService {
  /// Returns a compatibility score from 0–100 based on questionnaire.
  /// Weights:
  ///   sleep schedule     15%
  ///   cleanliness        15%
  ///   noise level        10%
  ///   friday night vibe  10%
  ///   guests frequency   10%
  ///   substances         20% (smoking 10% + drinking 5% + pets 5%)
  ///   rent budget        15%
  ///   lifestyle misc      5%
  static int calculateCompatibility(Questionnaire a, Questionnaire b) {
    double score = 0;

    // Sleep schedule (15%)
    score += _sleepScore(a.sleepSchedule, b.sleepSchedule) * 0.15;

    // Cleanliness (15%)
    score += _scaleScore(a.cleanliness, b.cleanliness, maxDiff: 4) * 0.15;

    // Noise level (10%)
    score += _noiseLevelScore(a.noiseLevel, b.noiseLevel) * 0.10;

    // Friday night vibe (10%)
    score += _fridayNightScore(a.fridayNight, b.fridayNight) * 0.10;

    // Guests frequency (10%)
    score += _guestsFrequencyScore(a.guestsFrequency, b.guestsFrequency) * 0.10;

    // Smoking (10%)
    score += (a.smoking == b.smoking ? 100 : 0) * 0.10;

    // Drinking (5%)
    score += (a.drinking == b.drinking ? 100 : 40) * 0.05;

    // Pets (5%)
    score += (a.pets == b.pets ? 100 : 20) * 0.05;

    // Rent budget (15%)
    score += _rentBudgetScore(a.rentBudget, b.rentBudget) * 0.15;

    // Lifestyle misc: kitchen + sharing comfort (5%)
    score += _lifestyleScore(a, b) * 0.05;

    return score.round().clamp(0, 100);
  }

  static double _sleepScore(String a, String b) {
    if (a == b) return 100;
    if (a == 'flexible' || b == 'flexible') return 65;
    return 15; // early_bird vs night_owl
  }

  static double _scaleScore(int a, int b, {required int maxDiff}) {
    final diff = (a - b).abs();
    return (1 - diff / maxDiff) * 100;
  }

  static double _noiseLevelScore(String a, String b) {
    const order = {'quiet': 0, 'background': 1, 'lively': 2};
    final aVal = order[a] ?? 1;
    final bVal = order[b] ?? 1;
    final diff = (aVal - bVal).abs();
    if (diff == 0) return 100;
    if (diff == 1) return 55;
    return 15; // quiet vs lively
  }

  static double _fridayNightScore(String a, String b) {
    if (a == b) return 100;
    // studying ↔ lowkey are compatible
    if ((a == 'studying' && b == 'lowkey') || (a == 'lowkey' && b == 'studying')) return 70;
    // lowkey ↔ party — somewhat compatible
    if ((a == 'lowkey' && b == 'party') || (a == 'party' && b == 'lowkey')) return 45;
    // studying ↔ party — incompatible
    return 15;
  }

  static double _guestsFrequencyScore(String a, String b) {
    const order = {'rarely': 0, 'monthly': 1, 'weekends': 2, 'always': 3};
    final aVal = order[a] ?? 1;
    final bVal = order[b] ?? 1;
    final diff = (aVal - bVal).abs();
    if (diff == 0) return 100;
    if (diff == 1) return 65;
    if (diff == 2) return 30;
    return 10;
  }

  static double _rentBudgetScore(String a, String b) {
    const order = {'under_600': 0, '600_900': 1, '900_1200': 2, '1200_plus': 3};
    final aVal = order[a] ?? 1;
    final bVal = order[b] ?? 1;
    final diff = (aVal - bVal).abs();
    if (diff == 0) return 100;
    if (diff == 1) return 65;
    if (diff == 2) return 25;
    return 5;
  }

  static double _lifestyleScore(Questionnaire a, Questionnaire b) {
    double score = 0;
    // Kitchen habits (50%)
    score += (a.kitchenHabits == b.kitchenHabits ? 100 : 50) * 0.5;
    // Sharing comfort (50%)
    const order = {'separate': 0, 'some': 1, 'share': 2};
    final diff = ((order[a.sharingComfort] ?? 1) - (order[b.sharingComfort] ?? 1)).abs();
    score += (diff == 0 ? 100 : diff == 1 ? 60 : 20) * 0.5;
    return score;
  }

  static String compatibilityLabel(int score) {
    if (score >= 90) return 'Perfect Match ✨';
    if (score >= 75) return 'Great Match 🔥';
    if (score >= 60) return 'Good Match 👍';
    if (score >= 45) return 'Fair Match';
    return 'Low Match';
  }
}
