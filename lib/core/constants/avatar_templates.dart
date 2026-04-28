/// Curated set of stylized illustrated avatars users can pick as their
/// profile photo when they don't want to upload a real picture.
///
/// Uses DiceBear's free avatar API (https://dicebear.com) — no API key
/// required, returns deterministic PNGs based on the `seed` query param.
/// Style is `avataaars-neutral` (cartoon characters, no real-people
/// likeness — appropriate for templates).
class AvatarTemplates {
  AvatarTemplates._();

  /// Stable seeds used to generate the 12 template avatars. Order matters:
  /// dummy users assigned via [pickFor] depend on it.
  static const List<String> _seeds = [
    'maple',
    'cedar',
    'willow',
    'aspen',
    'birch',
    'juniper',
    'sage',
    'clover',
    'rowan',
    'fern',
    'iris',
    'poppy',
  ];

  /// Builds a DiceBear URL for the given seed. Background is transparent
  /// so the circular avatar container shows through.
  static String _urlFor(String seed) =>
      'https://api.dicebear.com/7.x/avataaars-neutral/png'
      '?seed=$seed&size=400&backgroundColor=ffd6c4,c3543a,ffe4d6';

  /// All 12 picker options, in display order.
  static List<String> get all =>
      _seeds.map(_urlFor).toList(growable: false);

  /// Deterministic template assignment for a given user id. Dummy users in
  /// `MockData` use this so each one keeps the same avatar across hot
  /// reloads and reseeds.
  static String pickFor(String userId) {
    if (userId.isEmpty) return _urlFor(_seeds.first);
    // Simple stable hash → index in [0, _seeds.length)
    var h = 0;
    for (final c in userId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _urlFor(_seeds[h % _seeds.length]);
  }

  /// Returns true if [url] is one of the templates served by this module.
  /// Used by the picker to highlight the currently-selected template.
  static bool isTemplate(String url) =>
      url.startsWith('https://api.dicebear.com/');
}
