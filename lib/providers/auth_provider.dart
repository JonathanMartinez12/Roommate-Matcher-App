// Re-export all auth providers from auth_service.dart.
// Every screen that imports this file gets the full provider set without
// needing to know about the underlying Firebase implementation.
export '../services/auth_service.dart'
    show
        authStateProvider,
        authStateChangesProvider,
        authNotifierProvider,
        currentUserProvider,
        authServiceProvider,
        firebaseAuthProvider,
        AuthNotifier;
