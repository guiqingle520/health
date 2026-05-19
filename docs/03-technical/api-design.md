# API 设计

## 1. 基础约定

- Base URL：`/`
- 数据格式：REST JSON API
- 鉴权：Bearer Token
- 状态标签：`Current` 已实现，`Next` 近期建议，`Future` 远期方向

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

## 10. 我的页、报告、家庭、设备

### Next

- `GET /health/profile-center/me`：个人中心聚合信息。
- `GET /health/reports?period=week|month`：报告列表。
- `POST /health/reports/:id/export`：报告导出。
- `GET /health/notifications/settings` / `PUT /health/notifications/settings`：通知提醒设置。
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

## 11. 错误与权限演进

### Current

- NestJS 默认错误结构。
- 部分读取接口已鉴权，写入接口仍存在未鉴权历史设计。

### Next

- 统一错误码：`AUTH_REQUIRED`、`PROFILE_NOT_FOUND`、`VALIDATION_FAILED`、`RESOURCE_FORBIDDEN`。
- 所有用户健康数据读写都应绑定当前登录用户。
- 历史公开接口迁移为内部接口或增加权限控制。
