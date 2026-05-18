# API 设计

## 1. 基础约定

- Base URL：`/`
- 数据格式：REST JSON API
- 鉴权：Bearer Token
- 状态标签：`Current` 已实现，`Next` 近期建议，`Future` 远期方向

## 2. 认证接口

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

## 3. 健康档案接口

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

## 4. 饮食记录接口

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

## 5. 运动记录接口

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

## 6. 日汇总与仪表盘

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

## 7. 数据趋势

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

## 8. AI 建议

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

## 9. 我的页、报告、家庭、设备

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

### Future

- 家庭共享：成员、邀请、授权范围、审计记录。
- 设备接入：更多厂商绑定、同步记录、设备指标查询。
- Pro 会员：权益、订阅、报告权限。

## 10. 错误与权限演进

### Current

- NestJS 默认错误结构。
- 部分读取接口已鉴权，写入接口仍存在未鉴权历史设计。

### Next

- 统一错误码：`AUTH_REQUIRED`、`PROFILE_NOT_FOUND`、`VALIDATION_FAILED`、`RESOURCE_FORBIDDEN`。
- 所有用户健康数据读写都应绑定当前登录用户。
- 历史公开接口迁移为内部接口或增加权限控制。
