import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';

class RoomrApp extends ConsumerStatefulWidget {
  const RoomrApp({super.key});

  @override
  ConsumerState<RoomrApp> createState() => _RoomrAppState();
}

class _RoomrAppState extends ConsumerState<RoomrApp> {
  @override
  void initState() {
    super.initState();
    // Handle the initial auth state since ref.listen no longer supports fireImmediately.
    final authState = ref.read(authStateChangesProvider);
    if (authState.valueOrNull != null) {
      ref.read(notificationServiceProvider).init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Initialize push notifications when the user signs in. NotificationService.init() is idempotent.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (prev, next) {
      if (next.valueOrNull != null) {
        ref.read(notificationServiceProvider).init();
      }
    });

    return MaterialApp.router(
      title: 'Roomr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
