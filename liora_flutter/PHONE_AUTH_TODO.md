# Phone Auth TODO / Release Checklist

Keep this short checklist to verify iOS Phone Authentication works and to avoid regressions.

## Dev (Simulator) – working state
- [x] App verification disabled in debug to bypass reCAPTCHA/Safari
  - File: `lib/main.dart`
  - Code: `FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true)` inside `if (!kReleaseMode)`
- [x] Use Firebase test phone numbers (no SMS needed)
  - Firebase Console → Authentication → Phone → “Phone numbers for testing”

## iOS deep‑link plumbing
- [x] URL schemes present in `ios/Runner/Info.plist` → `CFBundleURLTypes`
  - `com.googleusercontent.apps.974985211075-2afc08615396933463c676`
  - `app-1-974985211075-ios-2afc08615396933463c676`
- [x] AppDelegate forwards auth callbacks to FirebaseAuth
  - File: `ios/Runner/AppDelegate.swift`
  - Overrides: `application(_:open:options:)`, `application(_:continue:)`, and legacy `application(_:open:sourceApplication:annotation:)`

## Quick test (simulator)
1. `flutter clean && flutter pub get && (cd ios && pod install && cd ..)`
2. `flutter run`
3. Enter a test phone number and its fixed code → should verify without opening Safari.

## Before shipping (physical device)
- [ ] Keep the debug guard as-is; the `!kReleaseMode` check ensures verification is NOT disabled in release.
- [ ] Test on a real iPhone with a real number (expect reCAPTCHA at times).
- [ ] Confirm deep-link returns to the app (no “Page Not Found”).
- [ ] Remove Firebase “test phone numbers” from Console for production.

## Troubleshooting notes
- If you see “We have blocked all requests from this device…”, you are rate‑limited:
  - Wait, change IP/network, or use Firebase test numbers.
- If Safari opens and you land on “Page Not Found”, deep‑link isn’t intercepted:
  - Recheck Info.plist schemes and AppDelegate URL handlers, then rebuild (not hot‑restart).


