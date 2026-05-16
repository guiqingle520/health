# 项目启动指南

本文档仅说明如何在本地启动当前仓库中的前后端应用。架构设计与路线图请查看 `docs/architecture.md`。

## 1. 环境要求

### 通用

- Node.js 20+
- npm 10+
- Git

### 后端

- NestJS 依赖由 `apps/backend/package.json` 管理
- 当前后端使用内存数据结构与 SQL 草案文件并行开发，启动本地 API 不依赖真实数据库

### 移动端

- Flutter 3.19+
- Dart SDK 3.3+
- Chrome（用于 Web 调试）或 Android / iOS 设备

## 2. 安装依赖

### 安装根目录依赖

```bash
npm install
```

### 安装后端依赖

```bash
cd apps/backend
npm install
```

### 安装移动端依赖

```bash
cd apps/mobile
flutter pub get
```

## 3. 启动后端

在 `apps/backend` 目录执行：

```bash
npm run start:dev
```

默认用途：
- 提供认证接口 `/auth/login`、`/auth/me`、`/auth/refresh`
- 提供健康档案、饮食记录、运动记录、仪表盘接口

如需构建生产包：

```bash
npm run build
npm run start:prod
```

## 4. 启动移动端

在 `apps/mobile` 目录执行：

```bash
flutter pub get
flutter run -d chrome
```

## 5. Android 调试与打包

```bash
cd apps/mobile
flutter devices
flutter run -d <deviceId>
flutter build apk --release
flutter build appbundle --release
```

产物位置：

- `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`

## 6. iOS 调试

仅限 macOS：

```bash
cd apps/mobile
open ios/Runner.xcworkspace
flutter run -d <iosDeviceId>
```

## 7. 常用命令

根目录可使用以下工作区脚本：

```bash
npm run backend:build
npm run backend:lint
npm run backend:test
```

后端目录常用命令：

```bash
npm run start:dev
npm run build
npm run test
npm run lint
```

## 8. 当前开发说明

当前仓库已实现的主要能力：

- 后端：NestJS API、JWT 登录、档案管理、饮食/运动记录、日汇总与仪表盘聚合
- 移动端：Flutter 登录、首次建档、仪表盘展示
- 数据层：`apps/backend/sql/m1_m2_schema.sql` 提供第一阶段数据库草案

如需理解模块关系、技术选型和后续路线图，请查看 `docs/architecture.md`。