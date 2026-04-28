# Roommate-Matcher-App
An app that is built on Flutter, Dart, and Firebase to help incoming university students find the perfect roommate match based off a comprehensive quiz. 

# Roomr — Setup & Run Guide

A walkthrough for getting the Roommate-Matcher-App running on a fresh
machine. Roomr is a Flutter application that uses Firebase for
authentication, data storage, and matching.

---

## Prerequisites

Install these once:

- **Flutter SDK** (3.x or newer) — https://docs.flutter.dev/get-started/install
- **Node.js + npm** (for the Firebase CLI) — https://nodejs.org
- **Git** — https://git-scm.com
- **Chrome** — used for the web build

After installing Flutter, verify it works:

```bash
flutter doctor
```

Green checkmarks on **Flutter** and **Chrome** are required. The
Android toolchain is optional and only needed if you want to run on a
phone or emulator.

---

## First-time setup

### 1. Clone the repo

```bash
git clone https://github.com/<your-org>/Roommate-Matcher-App.git
cd Roommate-Matcher-App
```

### 2. Install dependencies

```bash
flutter pub get
```

Reads `pubspec.yaml` and downloads every package the app needs. Takes
10–30 seconds.

### 3. Set up Firebase

The app talks to a Firebase project for authentication, Firestore, and
storage. The config file `lib/firebase_options.dart` contains the
connection details and is generated locally.

**Install the two CLIs:**

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

If `dart pub global activate` warns about your PATH, add
`%LOCALAPPDATA%\Pub\Cache\bin` (Windows) or `$HOME/.pub-cache/bin`
(Mac/Linux) to your PATH and restart the terminal.

**Log in to Firebase:**

```bash
firebase login
```

A browser opens — sign in with the Google account that has access to
the Roomr Firebase project.

**Generate the config file:**

```bash
flutterfire configure
```

When asked about the existing `firebase.json`, say **yes** to reuse
it. The CLI fetches configs for all platforms and writes
`lib/firebase_options.dart`.

### 4. Verify the file exists

```bash
# Windows
dir lib\firebase_options.dart

# Mac / Linux
ls lib/firebase_options.dart
```

Should print the file path. If it does, setup is complete.

---

## Running the app

From the project root:

```bash
flutter run -d chrome
```

First build takes 1–3 minutes. After that, hot reload is instant —
press `r` in the terminal to reload after code changes, or `R` for a
full restart.

### Targeting other devices

```bash
flutter devices                  # list everything available
flutter run -d windows           # native Windows desktop app
flutter run -d <android-id>      # physical Android phone (USB debugging on)
flutter run -d emulator-5554     # Android emulator (start it from Android Studio first)
```

---

## Common commands

| Command                     | What it does                                          |
| --------------------------- | ----------------------------------------------------- |
| `flutter pub get`           | Refresh dependencies after pulling new code           |
| `flutter run -d chrome`     | Launch the app in Chrome                              |
| `flutter clean`             | Nuke build artifacts (run if builds get weird)        |
| `flutter analyze`           | Static analysis — catches issues before runtime       |
| `r` (in running session)    | Hot reload                                            |
| `R` (in running session)    | Hot restart (resets app state)                        |
| `q` (in running session)    | Quit                                                  |

---

## Troubleshooting

### `Error: Error when reading 'lib/firebase_options.dart'`

Step 3 of first-time setup didn't complete. Re-run `flutterfire configure`.

### `Failed parsing lock file: Expected ':'`

The lock file got into a bad state. Regenerate it:

```bash
# Windows
del pubspec.lock

# Mac / Linux
rm pubspec.lock

flutter pub get
```

### `Unable to locate Android SDK`

Android Studio isn't installed. If you're only running on Chrome or
Windows desktop, this warning is harmless — ignore it.

### `flutterfire: command not found` after activating it

Your PATH doesn't include the pub cache binaries. On Windows, add
`%LOCALAPPDATA%\Pub\Cache\bin` to your PATH and restart PowerShell. On
Mac/Linux, add `export PATH="$PATH:$HOME/.pub-cache/bin"` to your
`~/.zshrc` or `~/.bashrc`.

### Firebase auth popups blocked in Chrome

Click the popup-blocked icon in the URL bar and allow popups for
`localhost`, then reload.

### Build is just stuck or weird errors after pulling new code

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

`flutter clean` deletes the build cache, which fixes most "it worked
yesterday" issues.
