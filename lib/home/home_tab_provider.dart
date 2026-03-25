import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared tab index for the main HomeScreen scaffold.
/// Exposed as a top-level provider so the DashboardScreen can trigger
/// tab switches (e.g. Quick Action → Discover) without creating a
/// circular import with home_screen.dart.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
