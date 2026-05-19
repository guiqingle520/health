# Garmin 设备接入设计

## 1. 接入目标

HealthGuard 希望接入 Garmin 手表 / 手环数据，减少用户手动记录成本，并让首页、数据趋势、AI 建议和报告使用更连续的健康指标。

首期目标是云端同步 Garmin Connect 中的健康数据，不做实时传感器流。

## 2. 官方接入方式

### Garmin Health API - 推荐首期方案

- 类型：云到云集成。
- 授权：Garmin Connect Developer Program 使用 OAuth 2.0。
- 数据来源：用户设备同步到 Garmin Connect 后，HealthGuard 再通过 API 获取或接收数据。
- 数据范围：步数、心率、睡眠、压力、血氧、Body Battery、卡路里、强度分钟、呼吸、体成分、血压等。
- 同步方式：Garmin 官方支持 Ping/Pull 或 Push Architecture，适合后端统一处理数据。
- 前置条件：需要申请 Garmin Connect Developer Program，面向企业 / 商业用途审批。

### Garmin Health SDK - 远期评估

- 类型：移动端直接集成 Garmin 设备。
- 适合场景：实时心率、压力、加速度、传感器流或不经过 Garmin 云的数据托管。
- 代价：需要移动端 SDK、设备配对、商业授权与更多端侧适配。

## 3. 本项目推荐方案

### Next

采用 Garmin Health API：

```text
Mobile App
  -> POST /health/devices/garmin/connect
  -> Garmin OAuth 授权页
  -> /integrations/garmin/oauth/callback
  -> connected_devices 保存授权关系
  -> backfill 拉取历史数据
  -> Redis sync lock / webhook dedupe
  -> webhook / pull 同步增量数据
  -> health_metric_events 标准化指标
  -> dashboard / trends / AI / reports
```

### 不采用

- 不使用非官方 Garmin Connect 抓取、模拟登录或第三方逆向库。
- 不把 Garmin 数据直接写入业务卡片表；先进入标准化指标事件，再由聚合层消费。
- 不把 Garmin access token / refresh token 存入 Redis；token 必须加密落 PostgreSQL 或专用密钥存储。

## 4. 内部 API 设计

### `POST /health/devices/garmin/connect`

创建授权链接。

```json
{
  "authorizationUrl": "https://connect.garmin.com/oauth/...",
  "state": "signed-state"
}
```

### `GET /integrations/garmin/oauth/callback`

处理 OAuth 回调，校验 `state`，交换 token，保存连接状态。

成功后跳回 App：

```text
healthguard://devices/garmin/connected
```

### `GET /health/devices/connections`

返回用户设备连接状态。

```json
[
  {
    "provider": "garmin",
    "status": "connected",
    "lastSyncedAt": "2026-05-18T10:30:00+08:00",
    "metrics": ["steps", "heart_rate", "sleep", "stress"]
  }
]
```

### `POST /integrations/garmin/webhook`

接收 Garmin 推送事件或数据通知。该接口应使用 Garmin 配置的签名或共享密钥校验。

### `POST /health/devices/garmin/backfill`

触发历史数据补拉。建议限制时间范围和调用频率。

### `DELETE /health/devices/garmin`

断开授权，停止同步，并将连接状态置为 `revoked`。

## 5. 数据映射

| Garmin 指标 | 内部 `metric_type` | 用途 |
|---|---|---|
| Steps | `steps` | 首页步数、数据趋势 |
| Heart Rate | `heart_rate` | 数据趋势、异常提示 |
| Resting Heart Rate | `resting_heart_rate` | 数据趋势、AI 建议 |
| Sleep | `sleep_duration`、`sleep_score` | 睡眠卡片、AI 建议 |
| Stress | `stress` | AI 建议、报告 |
| Pulse Ox | `pulse_ox` | 数据趋势、报告 |
| Body Battery | `body_battery` | 恢复状态、AI 建议 |
| Calories | `calories_burned` | 热量消耗、日汇总 |
| Intensity Minutes | `intensity_minutes` | 运动活跃度 |

## 6. 数据库设计

首期需要：

- `connected_devices`
- `device_sync_logs`
- `device_metric_mappings`
- `health_metric_events`

token 必须加密存储，不写日志，不返回给客户端。

## 7. Redis 缓存与同步协调

### Next

Redis 在 Garmin 接入中主要解决短期状态、并发控制和热点状态读取，不作为设备数据权威存储。

| 场景 | Redis Key | TTL | 说明 |
|---|---|---|---|
| OAuth state | `oauth:garmin:state:{state}` | 10 分钟 | connect 时写入，callback 校验后删除，防止 CSRF 和重复回调。 |
| 连接状态缓存 | `health:device:connections:{userId}` | 5 分钟 | 我的页和设备页读取，连接、断开、同步状态变化后删除。 |
| backfill 同步锁 | `lock:garmin:sync:{providerUserId}` | 5-10 分钟 | 防止用户重复点击或任务重复触发同一时间段补拉。 |
| webhook 去重 | `dedupe:garmin:webhook:{eventDigest}` | 24 小时 | 防止重复 webhook 导致指标重复入库。 |
| 同步限流 | `rate-limit:garmin:sync:{userId}` | 窗口期 | 限制手动同步频率，避免触发 Garmin API 限制。 |

缓存失效要求：

- 授权成功、断开授权、token 刷新失败、同步状态变化后，删除 `health:device:connections:{userId}`。
- backfill 或 webhook 写入 `health_metric_events` 后，删除受影响用户的趋势、首页、报告和 AI 建议缓存。
- Redis 不可用时，OAuth callback 不能跳过 state 校验；如果 state 存储不可用，应拒绝授权并提示稍后重试。普通连接状态缓存和同步锁失败则降级为数据库路径与数据库唯一约束兜底。

## 8. 前端体验

入口：`我的 -> 设备与数据源 -> Garmin`。

页面状态：

- 未连接：展示 Garmin 能同步的指标和授权按钮。
- 授权中：展示跳转和等待状态。
- 已连接：展示最近同步时间、指标范围、手动同步、断开连接。
- 同步失败：展示失败原因和重试入口。
- 无数据：说明需先在 Garmin Connect 完成设备同步。

## 9. 隐私与合规

- 授权前必须说明同步范围和用途。
- 用户可随时断开授权。
- Garmin 数据只用于健康展示、趋势、报告和建议。
- 不将 Garmin 数据用于训练外部 AI / LLM。
- 家庭共享 Garmin 数据必须再次经过用户授权。

## 10. 失败与重试

- OAuth state 校验失败：拒绝连接。
- token 过期：尝试 refresh，失败后标记为 `reauth_required`。
- Garmin 数据延迟：保留旧数据并提示最近同步时间。
- webhook 重复：基于 provider、source_record_id、metric_type、recorded_at 去重。
- backfill 失败：写入 `device_sync_logs`，允许用户或任务重试。
- Redis 同步锁未获取：返回“同步进行中”或忽略重复任务，不创建新的 backfill。
- Redis 去重标记已存在：webhook 返回成功或幂等结果，不重复写指标事件。

## 11. 实施步骤

1. 申请 Garmin Connect Developer Program 并确认 Health API 权限。
2. 配置 OAuth redirect URI、webhook endpoint、签名校验方式。
3. 配置 Redis `oauth state`、同步锁、webhook 去重和连接状态缓存。
4. 新增设备连接表与同步日志表。
5. 实现 OAuth 授权、callback、断开连接。
6. 实现 backfill 和 webhook 数据标准化。
7. 将 Garmin 指标接入数据趋势和仪表盘。
8. 将睡眠、压力、Body Battery 接入 AI 建议。
9. 增加同步失败、断权、空数据、重复 webhook、Redis 降级的 QA 用例。
