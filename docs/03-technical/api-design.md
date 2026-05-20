# API 设计

## 1. 基础约定

- Base URL：`/`
- 数据格式：REST JSON API
- 鉴权：Bearer Token
- 状态标签：`Current` 已实现，`Next` 近期建议，`Future` 远期方向
- 国际化：后续新增接口如涉及用户可见文案、错误提示、通知、报告或 AI 建议，必须支持 locale；错误响应优先返回稳定错误码，由客户端本地化展示。

## 2. Redis 缓存约定

### Next

Redis 作为服务端缓存中间件和短期协调层，不改变现有 API 路径、请求参数和响应结构。客户端不感知缓存命中与否，接口语义仍以 PostgreSQL 中的业务数据为准。

- 缓存模式：cache-aside。读取时先查 Redis，未命中再查数据库 / 聚合服务并回填。
- 写入失效：所有会影响档案、记录、指标、建议、设备状态的写接口，成功提交数据库后删除相关缓存。
- 降级规则：Redis 连接失败、读失败、写失败时，接口继续走数据库路径；缓存错误只记录日志和监控，不向客户端暴露 5xx。
- 安全边界：不缓存 Garmin access token / refresh token、refresh token 明文、验证码明文、敏感授权凭据；OAuth state、限流计数、同步锁只保存短 TTL。
- 推荐环境变量：`REDIS_URL`、`CACHE_ENABLED`、`CACHE_DEFAULT_TTL_SECONDS`、`CACHE_PREFIX=health`。

### 推荐缓存对象

| API / 场景 | Key 方向 | TTL | 失效触发 |
|---|---|---|---|
| `GET /health/profiles/me` | `health:profile:{userId}` | 10 分钟 | 档案 upsert |
| `GET /health/daily-summary/me` / `:userId` | `health:summary:{userId}:{date}` | 5 分钟 | 当日饮食、运动、饮水、睡眠、指标写入 |
| `GET /health/dashboard/today` | `health:dashboard:{userId}:{date}` | 1-2 分钟 | 档案更新、当日记录写入、Garmin 当日指标同步 |
| 历史记录列表 | `health:history:{type}:{userId}:{from}:{to}:{limit}` | 2 分钟 | 对应类型新增、编辑、删除 |
| `GET /health/trends` | `health:trends:{userId}:{metric}:{period}:{from}:{to}` | 10 分钟 | 指标事件写入、设备 backfill、手动指标修改 |
| `GET /health/ai/recommendations/today` | `health:ai:recommendations:{userId}:{date}` | 5 分钟 | 新指标写入、建议动作更新、重新生成建议 |
| `GET /health/reports` | `health:report:{userId}:{period}:{start}:{end}` | 30 分钟 | 周期内记录或指标变化 |
| `GET /health/devices/connections` | `health:device:connections:{userId}` | 5 分钟 | 连接、断开、同步状态更新 |

### 接口实现要求

- 缓存 key 必须包含 `userId` 或可证明安全的作用域，避免跨用户串读。
- 查询参数需要规范化后再拼 key，例如日期统一为 `YYYY-MM-DD`，列表 `limit` 使用默认值补齐。
- 写接口必须先完成数据库事务，再执行缓存删除；缓存删除失败不回滚业务写入，但需要记录可观察日志。
- 涉及日期范围的趋势和报告缓存，可优先删除用户级前缀或维护范围索引；首期允许采用保守删除策略。

## 3. 认证接口

### Current

| 方法 | 路径 | 说明 |
|---|---|---|
| `POST` | `/auth/login` | 手机号验证码登录，返回用户、access token、refresh token |
| `GET` | `/auth/me` | 获取当前用户 |
| `POST` | `/auth/refresh` | 使用 refresh token 刷新 token |

`POST /auth/login`

```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

### Next

- `POST /auth/code/send`：发送验证码。
- `POST /auth/logout`：退出登录并失效 refresh token。
- refresh token 轮换与设备会话管理。
- Redis 用于验证码发送频控、登录失败限流和短期 OAuth state；refresh token 仍持久化到数据库或安全存储，不写入 Redis 作为唯一依据。

## 4. 健康档案接口

### Current

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| `POST` | `/health/profiles` | 否 | 保存指定用户档案 |
| `POST` | `/health/profiles/me` | 是 | 当前用户 upsert 档案 |
| `GET` | `/health/profiles/me` | 是 | 当前用户档案，不存在返回 404 |
| `GET` | `/health/profiles/:userId` | 否 | 指定用户档案，不存在返回 null |

当前档案字段：

```json
{
  "nickname": "张先生",
  "age": 30,
  "gender": "male",
  "heightCm": 175,
  "weightKg": 72,
  "goal": "maintain"
}
```

### Next

- 收敛公开查询：`GET /health/profiles/:userId` 应增加权限控制或仅内部使用。
- 扩展档案详情：慢性病史、过敏史、用药情况、运动习惯。
- 档案 upsert 后失效：`health:profile:{userId}`、`health:dashboard:{userId}:*`、`health:profile-center:{userId}`。
- 基本信息编辑的字段、校验和 UI 方案见 [基本信息开发设计方案](./basic-profile-development.md)。

## 5. 饮食记录接口

### Current

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| `POST` | `/health/diet-records` | 否 | 新增饮食记录，当前由客户端传 `userId` |
| `GET` | `/health/diet-records?from&to&limit` | 是 | 当前用户饮食历史 |

写入请求：

```json
{
  "userId": "user-uuid",
  "mealType": "lunch",
  "foodName": "鸡胸肉沙拉",
  "nutrition": {
    "calories": 420,
    "carbs": 18,
    "protein": 35,
    "fat": 14,
    "fiber": 6,
    "sodiumMg": 520,
    "calciumMg": 110,
    "ironMg": 3.2,
    "vitaminAMcg": 180,
    "vitaminCMg": 25,
    "vitaminDIU": 40
  }
}
```

### Next

- `POST /health/diet-records/me`：鉴权写入当前用户记录。
- 支持 `recordedOn`，用于补录历史日期。
- `PATCH /health/diet-records/:id`、`DELETE /health/diet-records/:id`。
- `POST /health/diet-records/photo-estimation`：拍照识别入口，返回待确认营养估算。
- 写入、编辑、删除后失效对应日期的日汇总、首页、饮食历史、趋势和报告缓存。

## 5.1 记录中心接口

### Next

| 方法 | 路径 | 说明 |
|---|---|---|
| `GET` | `/health/records/center` | 记录中心聚合入口，返回饮食、运动、饮水、睡眠最近记录和快捷入口 |
| `GET` | `/health/records/center?date=YYYY-MM-DD` | 查看指定日期的四类记录 |

### 返回方向

```json
{
  "date": "2026-05-20",
  "sections": [
    { "type": "diet", "title": "饮食", "count": 3 },
    { "type": "exercise", "title": "运动", "count": 1 },
    { "type": "water", "title": "饮水", "count": 5 },
    { "type": "sleep", "title": "睡眠", "count": 1 }
  ],
  "quickActions": ["diet", "exercise", "water", "sleep"]
}
```

记录中心只做聚合，不做重计算。写入成功后需刷新对应日期的记录中心、日汇总、趋势和报告缓存。

## 6. 运动记录接口

### Current

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| `POST` | `/health/exercise-records` | 否 | 新增运动记录，当前由客户端传 `userId` |
| `GET` | `/health/exercise-records?from&to&limit` | 是 | 当前用户运动历史 |

写入请求：

```json
{
  "userId": "user-uuid",
  "exerciseType": "aerobic",
  "durationMinutes": 40,
  "caloriesBurned": 360
}
```

### Next

- `POST /health/exercise-records/me`：鉴权写入当前用户记录。
- 支持 `recordedOn`、运动强度、备注。
- 支持编辑和删除。
- 写入、编辑、删除后失效对应日期的日汇总、首页、运动历史、趋势和报告缓存。

## 7. 日汇总与仪表盘

### Current

| 方法 | 路径 | 鉴权 | 说明 |
|---|---|---|---|
| `GET` | `/health/daily-summary/:userId?date=YYYY-MM-DD` | 否 | 指定用户日汇总 |
| `GET` | `/health/dashboard/today?date=YYYY-MM-DD` | 是 | 当前用户今日仪表盘 |

`dashboard/today` 返回：

- `date`
- `healthScore`
- `profile`
- `cards`
- `aiInsights`
- `summary`

### Next

- `GET /health/daily-summary/me`：当前用户日汇总。
- 仪表盘增加 `companionContextSummary`、快捷记录状态、异常指标。
- 对未建档用户返回明确错误码或引导状态。
- Redis 缓存只缓存聚合后的响应对象，不能缓存未授权用户结果；未建档 404 不建议长时间缓存。

## 8. 数据趋势

### Next

`GET /health/trends?metric=weight|score|heartRate|calories|water|sleep&period=week|month|year`

返回方向：

```json
{
  "metric": "weight",
  "period": "week",
  "currentValue": 70.7,
  "delta": -1.0,
  "unit": "kg",
  "points": [
    { "date": "2026-05-02", "value": 71.2 }
  ],
  "signals": [
    { "level": "info", "message": "本周体重下降 1.0kg" }
  ]
}
```

趋势接口是 Redis 缓存优先级较高的读接口。按 `metric + period + from + to` 维度缓存聚合结果，Garmin backfill 或手动指标写入后必须失效受影响周期缓存。

### Next 设计要点

- 趋势指标至少覆盖体重、健康分、静息心率、热量、运动消耗、饮水、睡眠和目标达成率。
- 趋势点需要支持空数组返回，避免前端强依赖 mock。
- 目标变化时，趋势接口需要同步更新目标线或达成率。

## 9. AI 建议

### Next

| 方法 | 路径 | 说明 |
|---|---|---|
| `GET` | `/health/ai/recommendations/today` | 今日 AI 建议 |
| `POST` | `/health/ai/recommendations/:id/actions` | 采纳、稍后、忽略 |
| `POST` | `/health/ai/ask` | 问 AI |

建议对象方向：

```json
{
  "id": "recommendation-id",
  "type": "water",
  "title": "再喝 800ml 水",
  "reason": "今日饮水 1.2L，距离目标还差 800ml",
  "actionText": "采纳建议",
  "status": "pending"
}
```

建议列表可短 TTL 缓存，但建议动作必须落库。`POST /health/ai/recommendations/:id/actions` 成功后，应删除 `health:ai:recommendations:{userId}:{date}`，避免用户看到已处理建议再次处于待处理状态。

### Next 设计要点

- AI 建议优先来源于记录、趋势、目标和最近异常。
- 建议类型需覆盖饮水、睡眠、运动、饮食、目标偏离、趋势异常和用药提醒。
- 建议卡必须能回溯触发原因，避免只给结果不给解释。

## 10. 我的页、报告、家庭、设备

### Next

- `GET /health/profile-center/me`：个人中心聚合信息。
- `GET /health/reports?period=week|month`：报告列表。
- `POST /health/reports/:id/export`：报告导出。
- `POST /health/reports/:id/share`：创建分享链接或分享对象。
- `DELETE /health/reports/:id/share/:shareId`：撤销分享。
- `GET /health/notifications/settings` / `PUT /health/notifications/settings`：通知提醒设置。
- `GET /health/goals/me` / `PUT /health/goals/me`：目标设定和提醒。
- `GET /health/preferences/me` / `PUT /health/preferences/me`：语言、单位和显示偏好。国际化详细方案见 [国际化开发设计方案](./i18n-development.md)。
- Garmin 设备接入接口方向：
  - `GET /health/devices/connections`：当前用户已连接设备与同步状态。
  - `POST /health/devices/garmin/connect`：创建 Garmin OAuth 授权链接。
  - `GET /integrations/garmin/oauth/callback`：处理 Garmin OAuth 回调。
  - `POST /integrations/garmin/webhook`：接收 Garmin 推送数据或同步通知。
  - `POST /health/devices/garmin/backfill`：触发授权后的历史数据补拉。
  - `DELETE /health/devices/garmin`：断开 Garmin 授权。
- Redis 设备接入用途：
  - `oauth:garmin:state:{state}`：短期保存 OAuth state，TTL 10 分钟。
  - `health:device:connections:{userId}`：缓存设备连接列表，TTL 5 分钟。
  - `lock:garmin:sync:{providerUserId}`：backfill / webhook 同步锁，TTL 5-10 分钟。
  - `dedupe:garmin:webhook:{eventDigest}`：webhook 去重标记，TTL 24 小时。

### Future

- 家庭共享：成员、邀请、授权范围、审计记录。
- 设备接入：更多厂商绑定、同步记录、设备指标查询。
- Pro 会员：权益、订阅、报告权限。

## 10.1 通知与目标

### Next

- `GET /health/notifications/settings`：读取通知设置。
- `PUT /health/notifications/settings`：保存通知设置。
- `GET /health/goals/me`：读取当前用户目标列表。
- `PUT /health/goals/me`：批量保存当前用户目标。

### 约束

- 通知设置与目标保存后需同时刷新首页、记录中心、趋势、AI 建议和报告缓存。
- 目标接口必须校验周期、单位和数值范围。
- 通知提醒与目标设定都属于当前用户私有配置，只能读写本人数据。

## 11. 健康档案扩展接口

详细设计见 [健康档案 / 用药管理 / 体检报告开发方案](./health-profile-subfeatures-development.md)。

### Next

- `GET /health/profile-detail/me`：健康背景、完整度、数据来源和基础信息摘要。
- `PATCH /health/profile-detail/me`：更新慢病史、过敏史、家族史、运动习惯。
- `GET /health/medications`：获取用药列表和今日提醒状态。
- `POST /health/medications`：新增药品计划。
- `PATCH /health/medications/:id`：编辑药品计划。
- `POST /health/medications/:id/actions`：记录已服用、稍后、跳过。
- `GET /health/exam-reports`：体检报告列表。
- `GET /health/exam-reports/:id`：体检报告详情。
- `POST /health/exam-reports`：新增手动体检报告。
- `PATCH /health/exam-reports/:id`：更新体检报告摘要。
- `DELETE /health/exam-reports/:id`：删除未锁定报告。

### 约束

- 用药接口只做记录和提醒，不提供剂量建议。
- 体检报告接口只保留原始结果和参考范围，不输出诊断结论。
- 所有扩展接口在写入后需要失效 `profile-center`、相关列表缓存和首页摘要缓存。

## 12. 国际化接口约定

### Next

- 客户端请求头带 `Accept-Language` 和 `X-Locale`，例如 `zh-Hans`、`zh-Hant`、`en`、`ja`、`ko`。
- `X-Locale` 优先于 `Accept-Language`，服务端统一 normalize。
- `GET /health/preferences/me` 返回 `localeMode` 和 `locale`。
- `PUT /health/preferences/me` 保存 canonical locale。
- 后端错误响应返回稳定 `errorCode`，客户端本地化展示。
- AI 建议、健康报告、通知模板等生成类内容需要按 locale 生成，并在缓存 key 中包含 locale。

## 13. 错误与权限演进

### Current

- NestJS 默认错误结构。
- 部分读取接口已鉴权，写入接口仍存在未鉴权历史设计。

### Next

- 统一错误码：`AUTH_REQUIRED`、`PROFILE_NOT_FOUND`、`VALIDATION_FAILED`、`RESOURCE_FORBIDDEN`。
- 所有用户健康数据读写都应绑定当前登录用户。
- 历史公开接口迁移为内部接口或增加权限控制。
