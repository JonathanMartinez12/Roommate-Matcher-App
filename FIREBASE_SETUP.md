# Firebase Setup for Roomr

## Steps to configure Firebase:

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password)
3. Create Firestore Database
4. Enable Firebase Storage
5. Add Android app with package name: `com.roomr.app`
6. Download `google-services.json` → place in `android/app/`
7. Add iOS app and download `GoogleService-Info.plist` → place in `ios/Runner/`
8. Run: `flutterfire configure` to generate `lib/firebase_options.dart`

## Firestore Security Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /swipes/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /matches/{matchId} {
      allow read: if request.auth.uid in resource.data.userIds;
      allow create: if request.auth != null;
    }
    match /messages/{matchId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Storage Rules:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```
