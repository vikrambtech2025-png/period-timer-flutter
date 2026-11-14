# Period Timer (Flutter)

Exact Flutter port of the React Native Period Timer app.

## Prerequisites
- Flutter SDK 3.50+ (https://docs.flutter.dev/get-started/install/windows)
- Android SDK + JDK 17 (already at C:\Users\VIKRAM\.config\opencode\tools)
- Set FLUTTER_HOME and add flutter/bin to PATH

## Build
Run `build.bat` (sets ANDROID_HOME/JAVA_HOME and builds release APK).

Or manually:
```
flutter pub get
flutter build apk --release
```
APK output: `build\app\outputs\flutter-apk\app-release.apk`

## Install
```
adb uninstall com.periodtimer.flutter
adb install build\app\outputs\flutter-apk\app-release.apk
adb shell pm grant com.periodtimer.flutter android.permission.POST_NOTIFICATIONS
```

## Features
- Staff login (multiple accounts, salted SHA-256, reset via typing RESET)
- Day tabs Mon-Sat, single-day schedule view
- Edit Periods: names, hour:minute + AM/PM, per-day subject/faculty
- 42 weekly recurring alarms (7 periods x 6 days), buzzer sound
- Custom icon, offline, API 24+

## Notes
- flutter_local_notifications requires coreLibraryDesugaring (already enabled).
- OEM battery optimization may need manual whitelisting for alarms to fire.