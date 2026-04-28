import 'dart:math';

import '../models/user_model.dart';

/// Result returned by [IcebreakerService.generate].
///
/// [text] is the suggested icebreaker.
/// [isFresh] is `true` when the question was pulled from a still-uncycled
/// pool. When the entire pool has been shown, the service falls back to
/// re-using a question and sets [isFresh] to `false` so the caller can
/// reset its "seen" tracking and pull again to start a new cycle.
class IcebreakerSuggestion {
  final String text;
  final bool isFresh;

  const IcebreakerSuggestion(this.text, {required this.isFresh});
}

/// Generates handcrafted icebreaker questions tailored to two user
/// profiles. Each candidate question is gated by conditions on the two
/// users so the surfaced question always makes sense for the pair.
///
/// Pool design notes:
///   • Each conditional branch contributes 4–10 variations so that even
///     pairs with minimal overlap have a sizeable pool.
///   • A large set of profile-agnostic but warm/curious questions is
///     always added so the pool never falls below ~40 options.
///   • Combo branches fire when two attributes line up (e.g. same
///     university + same major) so common pairings get extra variety.
///
/// Cycle behavior:
///   • Caller passes the set of already-seen questions in [exclude].
///   • If any unseen candidates remain, one is picked at random with
///     `isFresh: true`.
///   • If every candidate has been seen, one is returned with
///     `isFresh: false` so the caller can reset its tracking.
class IcebreakerService {
  IcebreakerService({Random? random}) : _random = random ?? Random();

  final Random _random;

  IcebreakerSuggestion generate(
    UserModel me,
    UserModel? other, {
    Set<String> exclude = const {},
  }) {
    final candidates = _buildCandidates(me, other);
    final unique = candidates.toSet().toList();
    final fresh = unique.where((q) => !exclude.contains(q)).toList();

    if (fresh.isNotEmpty) {
      return IcebreakerSuggestion(
        fresh[_random.nextInt(fresh.length)],
        isFresh: true,
      );
    }
    if (unique.isEmpty) {
      return IcebreakerSuggestion(
        _genericFallbackPool(other).first,
        isFresh: true,
      );
    }
    // Pool exhausted — return a random previously-seen question and let
    // the caller decide whether to clear its tracking.
    return IcebreakerSuggestion(
      unique[_random.nextInt(unique.length)],
      isFresh: false,
    );
  }

  // ── Candidate generation ──────────────────────────────────────────────────

  List<String> _buildCandidates(UserModel me, UserModel? other) {
    final out = <String>[];
    final firstName = other?.firstName ?? '';
    final namePrefix = firstName.isNotEmpty ? 'Hey $firstName! ' : 'Hey! ';
    final q = me.questionnaire;
    final oq = other?.questionnaire;

    // ── University ─────────────────────────────────────────────────────────
    final sameUni = other != null &&
        other.university.isNotEmpty &&
        me.university.isNotEmpty &&
        other.university.toLowerCase().trim() ==
            me.university.toLowerCase().trim();
    if (sameUni) {
      final uni = other.university;
      out.addAll([
        '${namePrefix}Fellow $uni student! What\'s your favorite spot on campus?',
        'I see we\'re both at $uni — have you found a good study cafe nearby?',
        'Since we\'re both at $uni, what neighborhoods are you looking at to live in?',
        'What\'s the most underrated thing about $uni in your opinion?',
        'Got a favorite class or professor at $uni so far?',
        'What\'s the food scene like on your side of $uni\'s campus?',
        'Any $uni traditions or events you\'re looking forward to this year?',
        'What was the deciding factor for you picking $uni?',
        'Where do you usually go to escape campus for a bit?',
      ]);
    } else if (other != null && other.university.isNotEmpty) {
      final uni = other.university;
      out.addAll([
        '${namePrefix}I noticed you\'re at $uni — how do you like it there so far?',
        'What drew you to $uni in the first place?',
        'Best part about being a student at $uni?',
        'What\'s your favorite hangout spot near $uni?',
      ]);
    }

    // ── Major ──────────────────────────────────────────────────────────────
    final sameMajor = other != null &&
        other.major.isNotEmpty &&
        me.major.isNotEmpty &&
        other.major.toLowerCase().trim() == me.major.toLowerCase().trim();
    if (sameMajor) {
      final m = other.major;
      out.addAll([
        'Another $m major! What got you into it?',
        'Fellow $m student — what\'s the toughest class you\'ve taken so far?',
        'What part of $m are you most into right now?',
        'Where do you see yourself going after $m — grad school, industry, something else?',
        'Funniest/weirdest thing you\'ve had to do for a $m class?',
        'Got a favorite professor in the $m department?',
        'What\'s a $m-related thing you wish more people knew about?',
      ]);
    } else if (other != null && other.major.isNotEmpty) {
      final m = other.major;
      out.addAll([
        'I\'m curious — what made you pick $m as your major?',
        'What\'s a typical week like for someone studying $m?',
        'What do you love most about studying $m?',
        'If you weren\'t doing $m, what would you be studying instead?',
        'What\'s the most surprising thing you\'ve learned in $m so far?',
        'Coolest project or assignment you\'ve had in $m?',
      ]);
    }

    // ── Combo: same university + same major ────────────────────────────────
    if (sameUni && sameMajor) {
      out.addAll([
        'We\'re at the same school in the same major — how have I not seen you in class?',
        'Same school, same major — got a study group going? Could use one.',
        'Wild we haven\'t crossed paths yet. Which classes are you in this semester?',
      ]);
    }

    // ── Sleep schedule ─────────────────────────────────────────────────────
    final mySleep = q?.sleepSchedule;
    final oSleep = oq?.sleepSchedule;
    if (mySleep == 'early_bird' && oSleep == 'early_bird') {
      out.addAll([
        'Looks like we\'re both early birds — what\'s your go-to morning routine?',
        'Fellow early riser! Coffee or tea to start the day?',
        'What time does your alarm go off on a normal day?',
        'Best thing about being an early riser, in your opinion?',
        'Are you a "ease into it" morning person or "feet on the floor and go"?',
        'Got a favorite morning workout or walk routine?',
      ]);
    } else if (mySleep == 'night_owl' && oSleep == 'night_owl') {
      out.addAll([
        'Two night owls — what do you usually get up to past midnight?',
        'Late-night kindred spirit. What\'s your go-to late-night snack?',
        'What\'s the latest you\'ve been up this week, no judgment?',
        'Are you more of a "late-night project" person or a "late-night unwind" person?',
        'Got a favorite late-night show or podcast?',
        'What\'s your record for staying up working on something?',
      ]);
    } else if (mySleep == 'flexible' && oSleep == 'flexible') {
      out.addAll([
        'We\'re both pretty flexible with sleep — does that mean you adapt easily or you\'re kind of all over the place?',
        'When you sleep "whenever," what does a typical day actually look like for you?',
        'Do you have a sleep ritual that helps you wind down?',
      ]);
    } else if (mySleep != null && oSleep != null && mySleep != oSleep) {
      out.addAll([
        'I see our sleep schedules are pretty different — how do you usually keep things peaceful with roommates on that front?',
        'How particular are you about quiet hours?',
        'When you have a roommate on a different schedule, what helps it work?',
      ]);
    }

    // ── Cleanliness ────────────────────────────────────────────────────────
    final myClean = q?.cleanliness;
    final oClean = oq?.cleanliness;
    if (myClean != null && oClean != null) {
      if (myClean >= 4 && oClean >= 4) {
        out.addAll([
          'Looks like we both like a tidy place — do you have a cleaning routine that works for you?',
          'Are you a "clean as you go" person or a "Saturday morning deep clean" person?',
          'What\'s the one mess you absolutely cannot live with?',
          'Got a favorite cleaning product? I take recommendations seriously.',
        ]);
      } else if (myClean <= 2 && oClean <= 2) {
        out.addAll([
          'Sounds like neither of us is super uptight about tidiness — that\'s honestly nice. What\'s your idea of "clean enough"?',
          'How do you handle dishes? Asking for science.',
          'What\'s your stance on the floor as additional storage?',
        ]);
      } else if ((myClean - oClean).abs() >= 2) {
        out.addAll([
          'How do you usually split up cleaning with roommates? Curious how you like to handle it.',
          'Do you prefer a chore chart or a "whoever sees it does it" approach?',
          'What\'s a cleaning habit you\'ve picked up that you\'d never give up?',
        ]);
      } else {
        out.addAll([
          'How do you and roommates usually figure out cleaning?',
          'Are you a planner about cleaning or more of a "vibes" cleaner?',
        ]);
      }
    }

    // ── Noise tolerance ────────────────────────────────────────────────────
    final myNoise = q?.noiseTolerance;
    final oNoise = oq?.noiseTolerance;
    if (myNoise != null && oNoise != null) {
      if (myNoise <= 2 && oNoise <= 2) {
        out.addAll([
          'Looks like we both like a quieter home — what helps you wind down at the end of the day?',
          'Are you a "white noise" person, a "total silence" person, or something in between?',
          'What\'s a sound that drives you up the wall?',
          'Do you wear headphones around the house or prefer quiet rooms?',
        ]);
      } else if (myNoise >= 4 && oNoise >= 4) {
        out.addAll([
          'Sounds like neither of us mind a bit of noise — do you play music or have friends over a lot?',
          'What\'s on your "house party" playlist?',
          'You more of a "music in every room" person or "TV always on"?',
          'What\'s the loudest your place has ever gotten?',
        ]);
      } else if ((myNoise - oNoise).abs() >= 2) {
        out.addAll([
          'How particular are you about quiet hours, generally?',
          'When you\'ve got a roommate who\'s louder/quieter than you, what helps it work?',
        ]);
      }
    }

    // ── Study habits ───────────────────────────────────────────────────────
    final myStudy = q?.studyHabits;
    final oStudy = oq?.studyHabits;
    if (oStudy == 'at_home') {
      out.addAll([
        'I noticed you like studying at home — do you have a dedicated workspace setup, or roam around your place?',
        'What does your ideal at-home study setup look like?',
        'Music, podcast, or silence while you work?',
        'What helps you focus when you\'re working from home?',
      ]);
    } else if (oStudy == 'cafe') {
      out.addAll([
        'A cafe studier! Got a favorite spot you\'d recommend?',
        'Coffee shop or boba spot? Let\'s settle this.',
        'What is it about a cafe that helps you focus?',
        'How do you handle the "it\'s been 3 hours and I\'ve only ordered one drink" guilt?',
      ]);
    } else if (oStudy == 'library') {
      out.addAll([
        'Library person — silent floor or group study area?',
        'Do you have a favorite library on campus?',
        'How long is your average library session?',
        'Big spread-out study session or quick focused trips?',
      ]);
    } else if (oStudy == 'flexible') {
      out.addAll([
        'You study wherever — what\'s your dream study spot if you could pick anywhere?',
        'What was the weirdest place you\'ve gotten real work done?',
      ]);
    }
    if (myStudy != null && oStudy != null && myStudy == oStudy && myStudy != 'flexible') {
      out.addAll([
        'We both seem to study the same way — want to swap favorite spots sometime?',
        'Same study style — ever want to do a parallel work session?',
      ]);
    }

    // ── Guest policy ───────────────────────────────────────────────────────
    final myGuests = q?.guestPolicy;
    final oGuests = oq?.guestPolicy;
    if (myGuests == 'frequently' && oGuests == 'frequently') {
      out.addAll([
        'Sounds like we both like having people over — do you usually do dinners, game nights, something else?',
        'What\'s your go-to "people are coming over" setup?',
        'Big group hangouts or smaller close-knit ones?',
        'How do you balance "I love hosting" with "I also need to study"?',
      ]);
    } else if (myGuests == 'occasionally' && oGuests == 'occasionally') {
      out.addAll([
        'You and me both — sometimes-yes-sometimes-no on guests. What\'s your usual rhythm?',
        'When you do have people over, what\'s the vibe — chill hangout or planned event?',
      ]);
    } else if (myGuests == 'never' && oGuests == 'never') {
      out.addAll([
        'Looks like we both keep our place pretty private — that\'s nice. Are you more of a "go out" or "stay in" person on weekends?',
        'You seem to value your space at home — do you usually meet up with people elsewhere?',
        'Is the "no guests" thing about peace and quiet, or just keeping life separate?',
      ]);
    } else if (myGuests != null && oGuests != null) {
      out.addAll([
        'How do you usually handle the "having people over" conversation with roommates?',
        'What\'s your ideal guest-frequency in a roommate situation?',
      ]);
    }

    // ── Pets ───────────────────────────────────────────────────────────────
    final myPets = q?.pets;
    final oPets = oq?.pets;
    if (myPets == true && oPets == true) {
      out.addAll([
        'I noticed we both love pets — do you currently have one or are you hoping to get one?',
        'Cat person, dog person, both, or chaos creature?',
        'What\'s your pet (or dream pet)?',
        'Story of how you ended up with your pet?',
        'How do you handle pet duties when life gets busy?',
      ]);
    } else if (oPets == true && myPets == false) {
      out.addAll([
        'I saw you\'re into pets — what kind do you have or want?',
        'Tell me about your pet — I\'m curious!',
      ]);
    }

    // ── Drinking ───────────────────────────────────────────────────────────
    final myDrink = q?.drinking;
    final oDrink = oq?.drinking;
    if (myDrink == true && oDrink == true) {
      out.addAll([
        'Are you more of a "wine on the couch" or "cocktail bar" person?',
        'Got a go-to bar or spot in town?',
        'Beer, wine, or cocktails — desert island pick?',
        'House parties or going out, which do you prefer?',
      ]);
    } else if (myDrink == false && oDrink == false) {
      out.addAll([
        'I see we\'re both pretty chill on the drinking front — how do you usually like to spend a night out?',
        'Got a favorite non-alcoholic drink? Always looking for ideas.',
      ]);
    }

    // ── Smoking ────────────────────────────────────────────────────────────
    final mySmoke = q?.smoking;
    final oSmoke = oq?.smoking;
    if (mySmoke == false && oSmoke == false) {
      out.addAll([
        'Looks like we\'re aligned on the smoking thing — that always makes living together easier.',
      ]);
    }

    // ── Temperature preference ────────────────────────────────────────────
    final myTemp = q?.temperaturePreference;
    final oTemp = oq?.temperaturePreference;
    if (myTemp != null && oTemp != null) {
      if (myTemp != oTemp) {
        out.addAll([
          'Quick one — what temperature do you usually keep your place at? Trying to figure out if we\'d agree on the thermostat.',
          'Are you a "blanket and sweater" person or "windows open in winter" person?',
          'How do you feel about ceiling fans?',
          'Honest question — what\'s your dream thermostat setting?',
        ]);
      } else if (myTemp == 'cool') {
        out.addAll([
          'We\'re both cool-temp people — AC enthusiasts unite. What\'s your ideal thermostat?',
        ]);
      } else if (myTemp == 'warm') {
        out.addAll([
          'Both of us like it warm — agreed, sweaters indoors are not the move.',
        ]);
      }
    }

    // ── Bio-based ──────────────────────────────────────────────────────────
    if (other != null && other.bio.trim().isNotEmpty) {
      final bio = other.bio.trim();
      final snippet = _firstSentence(bio).trim();
      if (snippet.isNotEmpty && snippet.length <= 90) {
        out.addAll([
          'Your bio caught my eye — "$snippet". Tell me more about that?',
          'You wrote "$snippet" — what\'s the story behind that?',
        ]);
      } else {
        out.addAll([
          'I liked reading your bio — what\'s something about yourself you didn\'t put in there?',
          'Your bio gave me a vibe but I want to hear it from you — what should I know?',
        ]);
      }
      // Light keyword hooks
      final low = bio.toLowerCase();
      if (RegExp(r'\b(coffee|espresso|latte)\b').hasMatch(low)) {
        out.add(
            'I noticed coffee in your bio — what\'s your go-to order?');
      }
      if (RegExp(r'\b(travel|travell|backpack|abroad)\b').hasMatch(low)) {
        out.add(
            'You mentioned travel — favorite trip you\'ve taken?');
      }
      if (RegExp(r'\b(cook|cooking|baker|baking|food|foodie)\b').hasMatch(low)) {
        out.add(
            'I saw food in your bio — what\'s your signature dish?');
      }
      if (RegExp(r'\b(gym|workout|run|running|hike|hiking|yoga|climb)\b').hasMatch(low)) {
        out.add(
            'You sound active — what\'s your main movement of choice?');
      }
      if (RegExp(r'\b(music|guitar|piano|sing|band|concert)\b').hasMatch(low)) {
        out.add(
            'You mentioned music — got an artist on heavy rotation right now?');
      }
      if (RegExp(r'\b(read|book|novel|reader)\b').hasMatch(low)) {
        out.add(
            'You read! Best book you\'ve picked up this year?');
      }
      if (RegExp(r'\b(film|movie|cinema|tv|show)\b').hasMatch(low)) {
        out.add(
            'I saw movies/shows in your bio — what are you watching right now?');
      }
      if (RegExp(r'\b(game|gaming|gamer|console|pc)\b').hasMatch(low)) {
        out.add(
            'You game — what\'s in rotation right now?');
      }
      if (RegExp(r'\b(art|paint|draw|design|photograph)\b').hasMatch(low)) {
        out.add(
            'You\'re into art — do you create or mostly appreciate?');
      }
    }

    // ── Age (light, only if close) ────────────────────────────────────────
    if (other != null && other.age > 0 && me.age > 0) {
      final diff = (other.age - me.age).abs();
      if (diff <= 1) {
        out.addAll([
          'We\'re basically the same age — what year of school are you in?',
          'Same-ish age — first year living off campus, or have you been doing this a while?',
        ]);
      }
    }

    // ── Always-available "warm and curious" pool ──────────────────────────
    // These work regardless of what data is filled in, and ensure even
    // sparsely-filled profiles still get a deep pool.
    out.addAll([
      '${namePrefix}What made you swipe right on my profile?',
      '${namePrefix}What\'s the most important thing for you in a roommate?',
      'What\'s a non-negotiable for you in a living situation?',
      'What does your perfect Sunday look like?',
      'Are you more of a homebody or always out and about?',
      'What\'s a small thing that immediately makes a place feel like home to you?',
      'Coffee, tea, or "I refuse to function before noon"?',
      'What\'s the best meal you\'ve made (or attempted) recently?',
      'What show have you been watching lately?',
      'What\'s a hobby you\'ve been getting into?',
      'If you could live anywhere for a year, where would it be?',
      'What\'s your go-to comfort food?',
      'How do you usually decompress after a long day?',
      'Are you a planner or a "see what happens" person?',
      'What\'s something you\'re looking forward to this month?',
      'What\'s the best concert/show/event you\'ve been to recently?',
      'Do you have a "Sunday reset" routine?',
      'What\'s your stance on doing dishes immediately vs. "later"?',
      'Are you the kind of person who decorates a place, or "as long as it has a bed"?',
      'What\'s a roommate green flag for you?',
      'What\'s a roommate red flag, in your opinion?',
      'What\'s your relationship with grocery shopping — love it or chore?',
      'Big breakfast person or grab-and-go?',
      'How do you feel about shared groceries vs. everyone gets their own shelf?',
      'Do you have any "must-haves" for a place — washer/dryer, dishwasher, balcony?',
      'What\'s the longest you\'ve lived with a roommate? How did it go?',
      'Tell me one thing you wish your last roommate did differently.',
      'What\'s something you do for fun that surprises people?',
      'If money were no object, what would you do tomorrow?',
      'What\'s the last thing that genuinely made you laugh?',
      'What\'s your top "ick" in a shared kitchen?',
      'Are you a plants-everywhere person or "I will kill anything green"?',
      'What\'s your ideal Friday night look like?',
      'Are you more of a "decorate for every season" person or "minimalist all year"?',
      'What\'s the best book or podcast you\'ve consumed recently?',
      'How many alarms do you set in the morning, honestly?',
      'What\'s a small joy in your daily routine?',
      'Do you have a "first thing when I get home" ritual?',
      'What\'s a place near here you keep meaning to check out?',
      'How do you feel about candles — love them, fire hazard, or indifferent?',
    ]);

    return out;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _firstSentence(String s) {
    final trimmed = s.trim();
    final stop = trimmed.indexOf(RegExp(r'[.!?\n]'));
    if (stop == -1) return trimmed;
    return trimmed.substring(0, stop);
  }

  List<String> _genericFallbackPool(UserModel? other) {
    final firstName = other?.firstName ?? '';
    final prefix = firstName.isNotEmpty ? 'Hey $firstName! ' : 'Hey! ';
    return [
      '${prefix}What made you swipe right on my profile?',
      '${prefix}What are you looking for most in a roommate?',
      '${prefix}What\'s your ideal living situation?',
      '${prefix}Are you more of a homebody or always out and about?',
      '${prefix}What does a perfect Sunday look like for you?',
    ];
  }
}
