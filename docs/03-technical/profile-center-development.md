# 我的模块技术开发方案

## 1. 模块定位

“我的”模块是用户个人健康资料、报告、设备数据源、家庭共享、通知偏好、隐私安全和帮助支持的统一入口。首期目标不是做复杂设置中心，而是为 App 四 Tab 主结构提供可开发、可联调、可验收的个人中心模块。

状态标签：

- `Current`：当前代码已具备登录、建档、档案读取、仪表盘主流程，可作为我的模块数据来源。
- `Next`：近期开发目标，本文写到页面、接口、数据对象和验收标准。
- `Future`：远期能力，只定义边界，不作为当前实现承诺。

## 2. 功能范围

### Next

| 功能 | 说明 | 首期交付 |
|---|---|---|
| 个人资料卡 | 展示头像占位、昵称、健康目标、档案完整度、坚持天数、平均健康分 | 是 |
| 健康档案 | 查看和编辑基础档案：昵称、年龄、性别、身高、体重、目标 | 是 |
| 数据与报告 | 报告入口、记录历史入口、目标设定入口 | 是 |
| 设备与数据源 | Garmin 连接状态、最近同步时间、同步指标、连接 / 断开入口 | 是 |
| 通知提醒 | 饮水、运动、睡眠、报告生成等提醒开关 | 是 |
| 显示与单位 | 体重、身高、能量单位、语言与地区；深色模式预留 | 部分 |
| 隐私安全 | 隐私政策、数据授权说明、账号安全入口、退出登录 | 是 |
| 帮助支持 | FAQ、联系客服、关于我们 | 是 |

### Future

- Pro 会员中心、权益状态、订阅管理。
- 家庭共享详情、成员邀请、共享权限管理。
- 医生 / 健康顾问授权。
- 多设备登录管理和安全事件审计。

## 3. 页面与 UI 方案

### 页面结构

```text
ProfileCenterPage
  ProfileHeaderCard
  ProfileCompletionCard
  QuickActionGrid
  HealthProfileSection
  DataReportSection
  DeviceSourceSection
  FamilySharingSection
  SettingsPreferenceSection
  PrivacySecuritySection
  HelpSupportSection
  LogoutButton
```

### 布局规范

- 页面类型：底部导航中的“我的”Tab，允许长滚动。
- 背景：沿用 App 功能页浅绿灰背景。
- 卡片：白底、圆角 20-24、轻投影，与 `UI/app-profile.svg` 风格一致。
- 分组标题：使用短标题，不加解释性大段文案。
- 分组项：左侧 icon + 标题 + 可选副标题，右侧状态文本或箭头。
- 高风险操作：退出登录、断开设备授权使用底部确认弹层。
- 加载态：顶部资料卡和分组列表使用骨架屏。
- 错误态：保留页面结构，失败分组展示重试按钮。
- 无数据态：报告、设备、家庭共享使用分组内空态，不跳转空白页。

### 信息架构

| 分区 | UI 内容 | 点击行为 |
|---|---|---|
| 个人资料卡 | 昵称、目标、平均健康分、坚持天数、档案完整度 | 进入健康档案编辑 |
| 快捷操作 | 健康报告、目标设置、设备数据、通知提醒 | 跳转对应子页 |
| 健康档案 | 基础信息、健康背景、用药管理、体检报告 | 进入健康档案子功能，详细方案见 [健康档案 / 用药管理 / 体检报告开发方案](./health-profile-subfeatures-development.md) |
| 数据与报告 | 周报、月报、记录历史、数据导出占位 | 报告列表和记录历史可进入 |
| 设备与数据源 | Garmin 状态、最近同步时间、指标范围 | 进入设备详情 |
| 家庭与共享 | 家人健康、共享设置 | 首期展示入口和授权提示 |
| 设置与偏好 | 通知提醒、显示设置、语言单位、国际化 | 通知、语言和单位可编辑 |
| 隐私安全 | 隐私政策、数据授权、账号安全 | 查看说明，账号安全首期展示登录手机号 |
| 帮助支持 | 使用帮助、联系客服、关于我们 | 静态页面或外链 |
| 退出登录 | 退出当前账号 | 清理本地 token 并返回登录页 |

## 4. 前端开发设计

### 路由

```text
/profile
/profile/edit
/profile/reports
/profile/devices
/profile/devices/garmin
/profile/notifications
/profile/preferences
/profile/privacy
/profile/help
```

Flutter 当前可先用页面枚举或 Navigator 路由实现；后续拆分路由库时保持路径语义不变。

### 页面状态

| 状态 | 触发 | UI 表现 |
|---|---|---|
| `loading` | 首次进入或下拉刷新 | 骨架屏 |
| `ready` | `profile-center` 成功 | 展示完整分组 |
| `partial` | 聚合接口部分字段为空 | 对应分组展示空态或占位 |
| `error` | 聚合接口失败且无本地缓存 | 页面内错误 + 重试 |
| `offline` | 网络不可用但有本地缓存 | 展示上次数据和更新时间 |
| `unauthorized` | access token 失效且 refresh 失败 | 清理登录态并跳转登录 |

### 前端数据模型

```dart
class ProfileCenterViewModel {
  UserSummary user;
  HealthProfileSummary profile;
  ProfileStats stats;
  List<QuickAction> quickActions;
  ReportSummary reports;
  DeviceConnectionSummary devices;
  FamilySharingSummary family;
  NotificationSettings notifications;
  UserPreferences preferences;
  AccountSecuritySummary security;
}
```

### 页面组件拆分

| 组件 | 输入 | 说明 |
|---|---|---|
| `ProfileHeaderCard` | `user`、`profile`、`stats` | 顶部资料卡 |
| `ProfileCompletionCard` | `completionRate`、`missingFields` | 档案完整度 |
| `QuickActionGrid` | `quickActions` | 4 个快捷入口 |
| `ProfileMenuSection` | `title`、`items` | 通用分组列表 |
| `DeviceStatusRow` | `provider`、`status`、`lastSyncedAt` | Garmin 状态行 |
| `LogoutConfirmSheet` | 无 | 退出确认 |

### 交互要求

- 下拉刷新只刷新 `GET /health/profile-center/me`，不自动触发 Garmin 同步。
- 点击 Garmin 未连接状态进入授权说明页，再由按钮发起连接。
- 点击 Garmin 已连接状态进入设备详情页，可查看同步指标、最近同步时间、手动同步、断开授权。
- 通知设置切换使用乐观更新，但接口失败必须回滚 UI。
- 编辑档案成功后返回“我的”，并刷新 `profile-center`。
- 基本信息编辑的详细字段、校验、接口和 UI 方案见 [基本信息开发设计方案](./basic-profile-development.md)。
- 健康档案、用药管理和体检报告的详细方案见 [健康档案 / 用药管理 / 体检报告开发方案](./health-profile-subfeatures-development.md)。
- 语言与单位的详细方案见 [国际化开发设计方案](./i18n-development.md)。
- 退出登录需要二次确认，成功后清理 access token、refresh token 和本地用户缓存。

## 5. 后端 API 设计

所有用户数据接口默认使用 `JwtAuthGuard`，服务端从 token `sub` 获取 `userId`，不接受客户端传入 `userId`。

### `GET /health/profile-center/me`

获取“我的”页聚合信息。

响应：

```json
{
  "user": {
    "id": "user-uuid",
    "phoneMasked": "138****8000",
    "nickname": "张先生",
    "avatarUrl": null
  },
  "profile": {
    "gender": "male",
    "age": 30,
    "heightCm": 175,
    "weightKg": 72,
    "goal": "maintain",
    "completionRate": 80,
    "missingFields": ["allergies", "medications"]
  },
  "stats": {
    "streakDays": 12,
    "averageHealthScore": 82,
    "recordsThisWeek": 18
  },
  "reports": {
    "latestReportId": "report-uuid",
    "latestPeriod": "week",
    "latestGeneratedAt": "2026-05-18T20:00:00+08:00",
    "unreadCount": 1
  },
  "devices": {
    "connectedCount": 1,
    "items": [
      {
        "provider": "garmin",
        "displayName": "Garmin",
        "status": "connected",
        "lastSyncedAt": "2026-05-18T10:30:00+08:00",
        "metrics": ["steps", "heart_rate", "sleep", "stress"]
      }
    ]
  },
  "family": {
    "enabled": false,
    "memberCount": 0,
    "pendingInvites": 0
  },
  "notifications": {
    "water": true,
    "exercise": true,
    "sleep": false,
    "weeklyReport": true
  },
  "preferences": {
    "weightUnit": "kg",
    "heightUnit": "cm",
    "energyUnit": "kcal",
    "localeMode": "manual",
    "locale": "zh-Hans"
  },
  "security": {
    "phoneBound": true,
    "lastLoginAt": "2026-05-18T09:00:00+08:00"
  }
}
```

失败：

| 状态码 | 错误码 | 说明 |
|---|---|---|
| 401 | `AUTH_REQUIRED` | 未登录或 token 失效 |
| 404 | `PROFILE_NOT_FOUND` | 未建档，引导进入建档页 |
| 500 | `PROFILE_CENTER_UNAVAILABLE` | 聚合失败 |

### `PATCH /health/profiles/me`

编辑基础健康档案。

请求：

```json
{
  "nickname": "张先生",
  "age": 30,
  "gender": "male",
  "heightCm": 175,
  "weightKg": 72,
  "goal": "fat_loss"
}
```

规则：

- `age`：1-120。
- `heightCm`：50-250。
- `weightKg`：20-300。
- `goal`：`fat_loss`、`muscle_gain`、`maintain`、`improve_sleep`、`improve_fitness`。
- 成功后失效 `health:profile:{userId}`、`health:profile-center:{userId}`、`health:dashboard:{userId}:*`。

### `GET /health/reports?period=week|month`

获取报告列表摘要。

响应：

```json
{
  "items": [
    {
      "id": "report-uuid",
      "period": "week",
      "title": "5 月第 3 周健康周报",
      "score": 82,
      "generatedAt": "2026-05-18T20:00:00+08:00",
      "status": "ready"
    }
  ]
}
```

### `GET /health/devices/connections`

获取设备连接状态。详见 [Garmin 设备接入设计](./garmin-integration.md)。

### `GET /health/notifications/settings`

获取通知设置。

响应：

```json
{
  "water": true,
  "exercise": true,
  "sleep": false,
  "weeklyReport": true,
  "quietHours": {
    "enabled": true,
    "start": "22:30",
    "end": "08:00"
  }
}
```

### `PUT /health/notifications/settings`

更新通知设置。

请求：

```json
{
  "water": true,
  "exercise": false,
  "sleep": true,
  "weeklyReport": true,
  "quietHours": {
    "enabled": true,
    "start": "22:30",
    "end": "08:00"
  }
}
```

规则：

- 更新成功后失效 `health:profile-center:{userId}`。
- 静默时间跨天时允许 `start > end`。

### `GET /health/goals/me`

获取当前用户目标列表。

### `PUT /health/goals/me`

批量保存当前用户目标。

请求示例：

```json
{
  "goals": [
    {
      "goalType": "water",
      "targetValue": 2000,
      "unit": "ml",
      "period": "daily",
      "reminderEnabled": true
    }
  ]
}
```

规则：

- 目标保存后失效 `health:profile-center:{userId}`、`health:dashboard:{userId}:*`、`health:trends:{userId}:*`、`health:report:{userId}:*`。
- 目标值必须与单位和周期匹配。
- 目标提醒开关与通知设置可以独立保存，但在首页入口里合并展示。

### `GET /health/preferences/me`

获取显示和单位偏好。

### `PUT /health/preferences/me`

更新显示和单位偏好。

请求：

```json
{
  "weightUnit": "kg",
  "heightUnit": "cm",
  "energyUnit": "kcal",
  "localeMode": "manual",
  "locale": "en"
}
```

### `POST /auth/logout`

退出登录。

规则：

- 服务端失效当前 refresh token。
- 客户端清理本地 token、用户缓存和页面状态。
- 成功后跳转登录页。

## 6. 后端模块设计

### 服务拆分

```text
ProfileCenterController
  -> ProfileCenterService
    -> ProfileRepository
    -> ReportRepository
    -> DeviceRepository
    -> NotificationSettingsRepository
    -> UserPreferencesRepository
    -> CacheService
```

### 聚合策略

- `ProfileCenterService.getMe(userId)` 负责聚合。
- 允许部分非核心模块为空，例如报告、设备、家庭共享。
- 档案缺失属于主路径阻断，应返回 `PROFILE_NOT_FOUND`。
- 聚合接口不应触发重型计算、报告生成、Garmin 同步或 AI 生成，只读已有摘要。

### 缓存策略

| Key | TTL | 失效触发 |
|---|---|---|
| `health:profile-center:{userId}` | 5 分钟 | 档案、报告、设备、通知、偏好、家庭共享状态变化 |
| `health:profile:{userId}` | 10 分钟 | 档案更新 |
| `health:device:connections:{userId}` | 5 分钟 | 设备授权、断开、同步状态变化 |

要求：

- 使用 cache-aside。
- Redis 失败不影响接口返回。
- 缓存对象不能包含 access token、refresh token、Garmin token。
- 缓存命中前必须完成 JWT 鉴权，不能公开访问缓存 key。

## 7. 数据库设计

### 复用 Current 表

- `users`
- `user_profiles`
- `auth_refresh_tokens`

### Next 推荐表

#### `notification_settings`

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | UUID PK | 用户 ID |
| `water_enabled` | BOOLEAN | 饮水提醒 |
| `exercise_enabled` | BOOLEAN | 运动提醒 |
| `sleep_enabled` | BOOLEAN | 睡眠提醒 |
| `weekly_report_enabled` | BOOLEAN | 周报提醒 |
| `quiet_hours_enabled` | BOOLEAN | 静默时间开关 |
| `quiet_hours_start` | VARCHAR(5) | HH:mm |
| `quiet_hours_end` | VARCHAR(5) | HH:mm |
| `goal_reminder_enabled` | BOOLEAN | 目标提醒 |
| `updated_at` | TIMESTAMPTZ | 更新时间 |

#### `health_goals`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | UUID PK | 目标 ID |
| `user_id` | UUID | 用户 ID |
| `goal_type` | VARCHAR | water / exercise_minutes / sleep_hours / steps / calories / weight |
| `target_value` | NUMERIC | 目标值 |
| `unit` | VARCHAR | 单位 |
| `period` | VARCHAR | daily / weekly / monthly |
| `start_date` | DATE | 开始日期 |
| `end_date` | DATE | 结束日期 |
| `reminder_enabled` | BOOLEAN | 目标提醒开关 |
| `status` | VARCHAR | active / paused / completed / archived |
| `source` | VARCHAR | manual / system |
| `created_at` | TIMESTAMPTZ | 创建时间 |
| `updated_at` | TIMESTAMPTZ | 更新时间 |

#### `user_preferences`

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | UUID PK | 用户 ID |
| `weight_unit` | VARCHAR(10) | `kg` / `lb` |
| `height_unit` | VARCHAR(10) | `cm` / `ft_in` |
| `energy_unit` | VARCHAR(10) | `kcal` / `kj` |
| `locale_mode` | VARCHAR(20) | `system` / `manual` |
| `locale` | VARCHAR(20) | `zh-Hans` 等 canonical locale |
| `updated_at` | TIMESTAMPTZ | 更新时间 |

#### `account_security_events`

Future，用于多设备登录和安全审计。

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | UUID PK | 事件 ID |
| `user_id` | UUID | 用户 ID |
| `event_type` | VARCHAR | login / logout / token_refresh |
| `ip_address` | VARCHAR | IP |
| `user_agent` | TEXT | 设备信息 |
| `created_at` | TIMESTAMPTZ | 发生时间 |

## 8. UI 子页面设计

### 健康档案编辑页

详细方案见 [基本信息开发设计方案](./basic-profile-development.md)。

字段：

- 昵称：必填，1-20 字。
- 性别：男 / 女 / 未设置。
- 年龄：数字输入。
- 身高：数字输入，单位 cm。
- 体重：数字输入，单位 kg。
- 健康目标：单选。

按钮：

- 保存：主按钮，固定底部。
- 取消：返回上一页。

状态：

- 保存中禁用按钮。
- 校验失败显示字段级错误。
- 保存成功 toast + 返回“我的”。

### 报告列表页

- 顶部周期切换：周报 / 月报。
- 列表展示报告标题、健康分、生成时间、状态。
- 无报告时展示“暂无报告”，提供返回数据页或记录入口。
- 报告生成失败时展示重试状态。

### 设备与数据源页

- Garmin 卡片：
  - 未连接：展示可同步指标和连接按钮。
  - 已连接：展示最近同步时间、指标范围、手动同步、断开授权。
  - 同步失败：展示失败原因和重试。
- 多厂商设备 Future 以列表占位，不在首期实现。

### 通知提醒页

- 饮水提醒开关。
- 运动提醒开关。
- 睡眠提醒开关。
- 周报提醒开关。
- 静默时间开关和时间选择。

### 显示与单位页

- 体重单位。
- 身高单位。
- 能量单位。
- 语言设置：中文简体、中文繁体、英文、日文、韩文，支持跟随系统语言。
- 深色模式 Future 占位。

### 隐私安全页

- 隐私政策。
- 数据授权说明。
- 已绑定手机号。
- 退出登录入口也可在此页保留。

## 9. 权限与安全

- 所有“我的”模块接口必须鉴权。
- 聚合接口只返回当前用户数据。
- 家庭共享入口不得展示家人数据，除非共享权限已生效。
- Garmin token 只加密存储在数据库或安全存储，不返回客户端，不进入 Redis。
- 退出登录必须清除本地 token 和缓存。
- 隐私政策、数据授权说明可静态展示，但授权状态必须来自后端。

## 10. 埋点与日志

### 前端埋点方向

- `profile_center_view`
- `profile_edit_submit`
- `profile_report_click`
- `profile_device_click`
- `garmin_connect_click`
- `notification_settings_update`
- `logout_confirm`

### 后端日志方向

- `profile_center_aggregate_failed`
- `profile_update_failed`
- `notification_settings_update_failed`
- `profile_center_cache_miss`
- `profile_center_cache_set_failed`

日志不得包含手机号明文、token、Garmin 授权凭据。

## 11. 开发任务拆分

### 前端

1. 新增 `ProfileCenterPage` 和底部导航入口。
2. 实现资料卡、快捷入口、分组列表通用组件。
3. 接入 `GET /health/profile-center/me`。
4. 实现健康档案编辑页和保存流程。
5. 实现设备与数据源页 Garmin 状态展示。
6. 实现通知提醒页和乐观更新回滚。
7. 实现显示与单位页。
8. 实现退出登录确认和登录态清理。
9. 补齐加载态、空态、错误态、无网络态。

### 后端

1. 新增 `ProfileCenterController` 和 `ProfileCenterService`。
2. 实现 `GET /health/profile-center/me` 聚合接口。
3. 完善 `PATCH /health/profiles/me` 校验和缓存失效。
4. 新增通知设置接口和表。
5. 新增目标列表接口和表。
6. 新增用户偏好接口和表。
7. 接入报告摘要和设备连接摘要。
8. 接入 Redis `profile-center` 缓存。
9. 增加 e2e：成功、未建档、未登录、缓存失效、跨用户隔离。

### 测试

1. 我的页聚合接口成功返回完整结构。
2. 未建档用户返回 `PROFILE_NOT_FOUND`。
3. 档案编辑成功后“我的”页资料刷新。
4. 通知设置保存失败时前端回滚。
5. Garmin 未连接 / 已连接 / 同步失败三种状态展示正确。
6. 退出登录后无法访问“我的”页。
7. Redis 不可用时聚合接口仍可返回。
8. 不同用户不能读取彼此 profile-center 缓存。

## 12. 验收标准

- “我的”Tab 可从底部导航进入，页面结构与 `UI/app-profile.svg` 风格一致。
- 个人资料卡展示昵称、目标、档案完整度、坚持天数和平均健康分。
- 健康档案可编辑，保存后返回并刷新。
- 数据与报告、设备与数据源、通知提醒、隐私安全、帮助支持入口可达。
- Garmin 连接状态和最近同步时间展示准确。
- 通知设置可读取、修改、失败回滚。
- 目标设定可读取、修改、失败回滚。
- 退出登录后清理本地 token 并返回登录页。
- `GET /health/profile-center/me` 不接受客户端 `userId`，只返回当前用户数据。
- Redis 缓存命中不改变响应结构，档案、设备、报告、通知变化后缓存失效。
- Redis 故障不影响核心读取，敏感凭据不进入缓存和日志。
