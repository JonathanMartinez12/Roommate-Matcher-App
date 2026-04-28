import 'dart:math';

import '../models/user_model.dart';

/// Generates handcrafted icebreaker questions tailored to the two user
/// profiles in a direct message. Each candidate question is gated by
/// conditions on the two profiles, so we only surface questions that
/// actually make sense given the context (e.g. don't suggest "fellow
/// pet lover" if neither user has pets).
///
/// The generator is deterministic-given-input only in the sense that the
/// candidate pool is deterministic; the final pick is randomized so
/// repeated taps of the icebreaker button surface variety.
class IcebreakerService {
  IcebreakerService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Returns a single icebreaker string. [me] is the user composing the
  /// message, [other] is the matched user being addressed.
  ///
  /// If [exclude] is provided, the generator avoids returning any string
  /// in that set (useful for "Generate New" so the user gets variety).
  /// Falls back to a generic question pool if no tailored question is
  /// available.
  String generate(
    UserModel me,
    UserModel? other, {
    Set<String> exclude = const {},
  }) {
    final candidates = _buildCandidates(me, other);
    final fresh = candidates.where((q) => !exclude.contains(q)).toList();
    final pool = fresh.isNotEmpty ? fresh : candidates;
    if (pool.isEmpty) {
      return _genericFallback(other);
    }
    return pool[_random.nextInt(pool.length)];
  }

  // ── Candidate generation ──────────────────────────────────────────────────

  List<String> _buildCandidates(UserModel me, UserModel? other) {
    final out = <String>[];
    final firstName = other?.firstName ?? '';
    final namePrefix = firstName.isNotEmpty ? 'Hey $firstName! ' : 'Hey! ';

    // ── University ─────────────────────────────────────────────────────────
    final sameUni = other != null &&
        other.university.isNotEmpty &&
        me.university.isNotEmpty &&
        other.university.toLowerCase().trim() ==
            me.university.toLowerCase().trim();
    if (sameUni) {
      out.add(
          '${namePrefix}Fellow ${other.university} student! What\'s your favorite spot on campus?');
      out.add(
          'I see we\'re both at ${other.university} — have you found a good study cafe nearby?');
      out.add(
          'Since we\'re both at ${other.university}, what neighborhoods are you looking at to live in?');
    } else if (other != null && other.university.isNotEmpty) {
      out.add(
          '${namePrefix}I noticed you\'re at ${other.university} — how do you like it there so far?');
    }

    // ── Major ──────────────────────────────────────────────────────────────
    final sameMajor = other != null &&
        other.major.isNotEmpty &&
        me.major.isNotEmpty &&
        other.major.toLowerCase().trim() == me.major.toLowerCase().trim();
    if (sameMajor) {
      out.add(
          'Another ${other.major} major! What got you into it?');
      out.add(
          'Fellow ${other.major} student — what\'s the toughest class you\'ve taken so far?');
    } else if (other != null && other.major.isNotEmpty) {
      out.add(
          'I\'m curious — what made you pick ${other.major} as your major?');
      out.add(
          'What\'s a typical week like for someone studying ${other.major}?');
    }

    // ── Sleep schedule ─────────────────────────────────────────────────────
    final mySleep = me.questionnaire?.sleepSchedule;
    final otherSleep = other?.questionnaire?.sleepSchedule;
    if (mySleep != null && otherSleep != null) {
      if (mySleep == 'early_bird' && otherSleep == 'early_bird') {
        out.add(
            'Looks like we\'re both early birds — what\'s your go-to morning routine?');
        out.add(
            'Fellow early riser! Coffee or tea to start the day?');
      } else if (mySleep == 'night_owl' && otherSleep == 'night_owl') {
        out.add(
            'Two night owls — what do you usually get up to past midnight?');
        out.add(
            'Late-night kindred spirit. What\'s your go-to late-night snack?');
      } else if ((mySleep == 'early_bird' && otherSleep == 'night_owl') ||
          (mySleep == 'night_owl' && otherSleep == 'early_bird')) {
        out.add(
            'I see our sleep schedules are pretty different — how do you usually keep things peaceful with roommates on that front?');
      }
    }

    // ── Cleanliness ────────────────────────────────────────────────────────
    final myClean = me.questionnaire?.cleanliness;
    final otherClean = other?.questionnaire?.cleanliness;
    if (myClean != null && otherClean != null) {
      if (myClean >= 4 && otherClean >= 4) {
        out.add(
            'Looks like we both like a tidy place — do you have a cleaning routine that works for you?');
      } else if ((myClean - otherClean).abs() >= 2) {
        out.add(
            'How do you usually split up cleaning with roommates? Curious how you like to handle it.');
      }
    }

    // ── Noise tolerance ────────────────────────────────────────────────────
    final myNoise = me.questionnaire?.noiseTolerance;
    final otherNoise = other?.questionnaire?.noiseTolerance;
    if (myNoise != null && otherNoise != null) {
      if (myNoise <= 2 && otherNoise <= 2) {
        out.add(
            'Looks like we both like a quieter home — what helps you wind down at the end of the day?');
      } else if (myNoise >= 4 && otherNoise >= 4) {
        out.add(
            'Sounds like neither of us mind a bit of noise — do you play music or have friends over a lot?');
      }
    }

    // ── Study habits ───────────────────────────────────────────────────────
    final myStudy = me.questionnaire?.studyHabits;
    final otherStudy = other?.questionnaire?.studyHabits;
    if (otherStudy != null) {
      if (otherStudy == 'at_home') {
        out.add(
            'I noticed you like studying at home — do you have a dedicated workspace setup, or roam around your place?');
      } else if (otherStudy == 'cafe') {
        out.add(
            'A cafe studier! Got a favorite spot you\'d recommend?');
      } else if (otherStudy == 'library') {
        out.add(
            'Library person — silent floor or group study area?');
      }
      if (myStudy != null && myStudy == otherStudy && otherStudy != 'flexible') {
        out.add(
            'We both seem to study the same way — want to swap favorite spots sometime?');
      }
    }

    // ── Guest policy ───────────────────────────────────────────────────────
    final myGuests = me.questionnaire?.guestPolicy;
    final otherGuests = other?.questionnaire?.guestPolicy;
    if (myGuests != null && otherGuests != null) {
      if (myGuests == 'frequently' && otherGuests == 'frequently') {
        out.add(
            'Sounds like we both like having people over — do you usually do dinners, game nights, something else?');
      } else if (myGuests == 'never' && otherGuests == 'never') {
        out.add(
            'Looks like we both keep our place pretty private — that\'s nice. Are you more of a "go out" or "stay in" person on weekends?');
      }
    }

    // ── Pets ───────────────────────────────────────────────────────────────
    final myPets = me.questionnaire?.pets;
    final otherPets = other?.questionnaire?.pets;
    if (myPets == true && otherPets == true) {
      out.add(
          'I noticed we both love pets — do you currently have one or are you hoping to get one?');
    } else if (otherPets == true && myPets == false) {
      out.add(
          'I saw you\'re into pets — what kind do you have or want?');
    }

    // ── Smoking / drinking ─────────────────────────────────────────────────
    final mySmoke = me.questionnaire?.smoking;
    final otherSmoke = other?.questionnaire?.smoking;
    if (mySmoke == false && otherSmoke == false) {
      // No question; absence isn't a great icebreaker hook.
    }
    final myDrink = me.questionnaire?.drinking;
    final otherDrink = other?.questionnaire?.drinking;
    if (myDrink == true && otherDrink == true) {
      out.add(
          'Are you more of a "wine on the couch" or "cocktail bar" person?');
    }

    // ── Temperature preference ────────────────────────────────────────────
    final myTemp = me.questionnaire?.temperaturePreference;
    final otherTemp = other?.questionnaire?.temperaturePreference;
    if (myTemp != null && otherTemp != null && myTemp != otherTemp) {
      out.add(
          'Quick one — what temperature do you usually keep your place at? Trying to figure out if we\'d agree on the thermostat.');
    }

    // ── Bio-based ──────────────────────────────────────────────────────────
    if (other != null && other.bio.trim().isNotEmpty) {
      final bioSnippet = _firstSentence(other.bio).trim();
      if (bioSnippet.isNotEmpty && bioSnippet.length <= 90) {
        out.add(
            'Your bio caught my eye — "$bioSnippet". Tell me more about that?');
      } else {
        out.add(
            'I liked reading your bio — what\'s something about yourself you didn\'t put in there?');
      }
    }

    // ── Age (light, only if close) ────────────────────────────────────────
    if (other != null && other.age > 0 && me.age > 0) {
      final diff = (other.age - me.age).abs();
      if (diff <= 1) {
        out.add(
            'We\'re basically the same age — what year of school are you in?');
      }
    }

    return out;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _firstSentence(String s) {
    final trimmed = s.trim();
    final stop = trimmed.indexOf(RegExp(r'[.!?\n]'));
    if (stop == -1) return trimmed;
    return trimmed.substring(0, stop);
  }

  String _genericFallback(UserModel? other) {
    final firstName = other?.firstName ?? '';
    final prefix = firstName.isNotEmpty ? 'Hey $firstName! ' : 'Hey! ';
    final pool = <String>[
      '${prefix}What made you swipe right on my profile?',
      '${prefix}What are you looking for most in a roommate?',
      '${prefix}What\'s your ideal living situation?',
      '${prefix}Are you more of a homebody or always out and about?',
      '${prefix}What does a perfect Sunday look like for you?',
    ];
    return pool[_random.nextInt(pool.length)];
  }
}
