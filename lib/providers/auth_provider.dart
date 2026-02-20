// Re-export auth providers from auth_service.dart for backward compatibility.
// All screens that import this file will get the correct providers.
export '../services/auth_service.dart'
    show
        authStateProvider,
        currentUserProvider,
        authServiceProvider,
        authNotifierProvider,
        AuthNotifier;
