# Setup Guide

## Backend

```bash
cd apps/backend
npm install
npm run start:dev
```

## Mobile

```bash
cd /home/runner/work/health/health/apps
flutter create mobile --platforms=android,ios,web
cd /home/runner/work/health/health/apps/mobile
flutter pub get
flutter run -d chrome
```

### Android device

```bash
cd /home/runner/work/health/health/apps/mobile
flutter devices
flutter run -d <deviceId>
flutter build apk --release
flutter build appbundle --release
```

APK output:

- `/home/runner/work/health/health/apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

### iOS device (macOS only)

```bash
cd /home/runner/work/health/health/apps/mobile
open ios/Runner.xcworkspace
flutter run -d <iosDeviceId>
```

## Workspace shortcuts

```bash
npm run backend:build
npm run backend:lint
npm run backend:test
```
