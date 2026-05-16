# Health App Architecture

## 1. 项目概览

该仓库是一个健康管理应用 monorepo，目标是围绕用户登录、个人档案、饮食记录、运动记录和健康仪表盘构建 MVP，并逐步扩展 AI 分析、报告、设备接入与家庭协作能力。

当前仓库以两个可运行应用为核心：

- `apps/backend`：NestJS 后端 API
- `apps/mobile`：Flutter 移动端客户端

## 2. Monorepo 结构

- `apps/mobile`：Flutter 客户端（Android / iOS / Web）
- `apps/backend`：NestJS 后端（REST API）
- `packages/shared`：共享类型定义预留目录
- `docs`：架构、启动与详细设计文档

## 3. 当前实现状态

### 3.1 后端

当前后端以 NestJS 模块化组织：

- `src/app.module.ts`：应用入口模块，注册 `AuthModule` 与 `HealthModule`
- `src/auth`：登录、JWT 鉴权、当前用户解析
- `src/health`：健康档案、饮食记录、运动记录、日汇总、仪表盘

已暴露的核心接口包括：

- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/refresh`
- `POST /health/profiles`
- `POST /health/profiles/me`
- `GET /health/profiles/me`
- `GET /health/profiles/:userId`
- `POST /health/diet-records`
- `POST /health/exercise-records`
- `GET /health/daily-summary/:userId`
- `GET /health/dashboard/today`

当前服务层以内存数据结构承载健康数据，便于 MVP 演示与接口联调；数据库落地结构已在 `apps/backend/sql/m1_m2_schema.sql` 中起草。

### 3.2 移动端

当前 Flutter 客户端已实现三段式主流程：

- 登录页
- 首次建档页
- 仪表盘页

`apps/mobile/lib/main.dart` 中当前应用状态流转为：

1. 用户输入手机号与验证码登录
2. 通过 token 拉取个人档案
3. 未建档则进入 onboarding
4. 已建档则直接加载 dashboard

## 4. 技术选型

### 4.1 当前代码采用

#### 移动端

- Flutter
- Dart
- `http`：调用后端 API
- Material 3：基础 UI 风格

#### 后端

- NestJS 11
- `@nestjs/jwt` + `passport-jwt`：JWT 鉴权
- `class-validator` + `class-transformer`：DTO 校验

#### 数据层

- 当前运行态：内存存储
- 当前设计态：SQL 草案位于 `apps/backend/sql/m1_m2_schema.sql`

### 4.2 推荐演进方向

结合当前代码与产品目标，建议后续演进采用：

- 移动端：Flutter + Riverpod + Dio
- 后端：NestJS + PostgreSQL
- 缓存与会话：Redis
- 报表与分析：按阶段引入时序聚合或物化视图
- AI 能力：独立分析服务或后端内聚合调用

这样既能保持与当前实现一致，又方便从 MVP 平滑升级。

## 5. 系统架构

```text
+-----------------------+
|   Flutter Mobile App  |
| login / onboarding    |
| dashboard / records   |
+-----------+-----------+
            |
            | HTTP JSON API
            v
+-----------------------+
|    NestJS Backend     |
|  AuthModule           |
|  HealthModule         |
+-----------+-----------+
            |
            | current state
            v
+-----------------------+
| in-memory data store  |
+-----------------------+

            |
            | target persistence
            v
+-----------------------+
| PostgreSQL / Redis    |
+-----------------------+
```

## 6. 模块职责划分

### 6.1 AuthModule

职责：

- 手机号验证码登录入口
- JWT access token 签发
- refresh token 刷新
- 当前用户身份解析

该模块是移动端进入业务流程的唯一认证入口。

### 6.2 HealthModule

职责：

- 用户档案保存与查询
- 饮食记录写入
- 运动记录写入
- 日汇总聚合
- 仪表盘数据组装
- AI 洞察文案拼装

当前 `HealthService` 已包含日摄入营养汇总、运动消耗汇总、健康分数计算与洞察生成逻辑，是 MVP 业务核心。

## 7. 关键数据流

### 7.1 登录与建档流

```text
Mobile LoginView
  -> POST /auth/login
  -> token
  -> GET /health/profiles/me
     -> profile 不存在：进入 onboarding
     -> profile 存在：进入 dashboard
```

### 7.2 建档完成后进入仪表盘

```text
OnboardingView
  -> POST /health/profiles/me
  -> GET /health/dashboard/today
  -> 展示健康分数、卡片数据、AI 洞察、日汇总
```

### 7.3 记录汇总流

```text
Diet / Exercise Record
  -> 写入 HealthService 内存集合
  -> getDailySummary(userId, date)
  -> getDashboard(userId, date)
  -> 返回汇总与洞察
```

## 8. MVP 范围（Phase 1）

Phase 1 以“可跑通主路径”为目标：

1. 用户注册/登录与个人资料管理
2. 饮食记录与营养汇总
3. 运动记录与消耗汇总
4. 日度卡路里与宏量营养仪表盘

MVP 阶段优先保证：

- 登录到仪表盘主路径闭环
- 接口结构稳定
- DTO 与前后端字段一致
- 后续数据库替换时接口层尽量少改动

## 9. 完整路线图

### Phase 1：MVP

目标：完成从登录、建档到仪表盘的基础闭环。

范围：

- 手机号验证码登录
- 基础用户档案
- 饮食与运动记录
- 日汇总与仪表盘

### Phase 2：智能化与增强记录

目标：提升记录效率与健康建议质量。

建议纳入：

- AI 饮食识别
- AI 建议与解释
- 自然语言记录
- 周报 / 月报
- 睡眠、饮水、用药等扩展记录
- 更稳定的 PostgreSQL 持久化

### Phase 3：生态扩展

目标：从个人健康工具扩展为家庭与设备连接平台。

建议纳入：

- 家庭成员共享
- 社交能力
- 可穿戴设备接入
- 专家咨询与 PC 报表
- 数据导出与报告分享

## 10. 数据与持久化演进建议

当前数据库草案包含：

- `users`
- `user_profiles`
- `auth_refresh_tokens`

这与当前代码中的登录与建档流程是对齐的，但还不足以完整承载饮食记录、运动记录和仪表盘聚合。后续建议补充：

- `diet_records`
- `exercise_records`
- `daily_summaries` 或聚合视图
- `health_events` 统一事件表（可选）

## 11. 文档索引

- 启动指南：`docs/setup.md`
- 数据库设计：`docs/design/database.md`
- API 设计：`docs/design/api.md`
- UI/UX 设计：`docs/design/ui-design.md`
