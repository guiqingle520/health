# Setup Guide

## Backend

```bash
cd apps/backend
npm install
npm run start:dev
```

## Mobile

```bash
cd apps
flutter create mobile --platforms=android,ios,web
cd mobile
flutter pub get
flutter run -d chrome
```

### Android device

```bash
cd apps/mobile
flutter devices
flutter run -d <deviceId>
flutter build apk --release
flutter build appbundle --release
```

APK output:

- `build/app/outputs/flutter-apk/app-release.apk`（在 `apps/mobile` 目录下）

### iOS device (macOS only)

```bash
cd apps/mobile
open ios/Runner.xcworkspace
flutter run -d <iosDeviceId>
```

## Workspace shortcuts

```bash
npm run backend:build
npm run backend:lint
npm run backend:test
```
