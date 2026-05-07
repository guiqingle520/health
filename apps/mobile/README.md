# health_mobile

Flutter 客户端（手机、Pad、Web）。

## 初始化

当前仓库仅保留了最小 Flutter 代码，请先在本地补齐工程骨架：

```bash
cd apps
flutter create mobile --platforms=android,ios,web
```

然后保留并合并已有业务入口文件：

- `apps/mobile/lib/main.dart`（或在 mobile 目录下使用 `lib/main.dart`）

## 安装依赖

```bash
cd apps/mobile
flutter pub get
```

## Android 本地真机部署

1. 手机开启开发者模式与 USB 调试
2. USB 连接后检查设备：

```bash
flutter devices
```

3. 直接安装并运行：

```bash
flutter run -d <deviceId>
```

4. 打正式安装包：

```bash
flutter build apk --release
flutter build appbundle --release
```

5. 产物路径：

- APK: `build/app/outputs/flutter-apk/app-release.apk`（在 `apps/mobile` 目录下）

## iOS 本地真机部署（仅 macOS）

```bash
cd apps/mobile
open ios/Runner.xcworkspace
```

在 Xcode 中配置 Team、Bundle Identifier、Signing 后，执行：

```bash
flutter run -d <iosDeviceId>
```

或在 Xcode 中 Archive 后安装/分发。

## 常见问题

- 设备未识别：`flutter doctor -v`，更换数据线并重新授权 USB 调试
- Android 构建失败：`flutter clean && flutter pub get`
- iOS 签名失败：检查证书、Provisioning Profile、Bundle ID 唯一性
