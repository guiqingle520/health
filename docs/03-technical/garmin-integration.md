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
  -> webhook / pull 同步增量数据
  -> health_metric_events 标准化指标
  -> dashboard / trends / AI / reports
```

### 不采用

- 不使用非官方 Garmin Connect 抓取、模拟登录或第三方逆向库。
- 不把 Garmin 数据直接写入业务卡片表；先进入标准化指标事件，再由聚合层消费。

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

## 7. 前端体验

入口：`我的 -> 设备与数据源 -> Garmin`。

页面状态：

- 未连接：展示 Garmin 能同步的指标和授权按钮。
- 授权中：展示跳转和等待状态。
- 已连接：展示最近同步时间、指标范围、手动同步、断开连接。
- 同步失败：展示失败原因和重试入口。
- 无数据：说明需先在 Garmin Connect 完成设备同步。

## 8. 隐私与合规

- 授权前必须说明同步范围和用途。
- 用户可随时断开授权。
- Garmin 数据只用于健康展示、趋势、报告和建议。
- 不将 Garmin 数据用于训练外部 AI / LLM。
- 家庭共享 Garmin 数据必须再次经过用户授权。

## 9. 失败与重试

- OAuth state 校验失败：拒绝连接。
- token 过期：尝试 refresh，失败后标记为 `reauth_required`。
- Garmin 数据延迟：保留旧数据并提示最近同步时间。
- webhook 重复：基于 provider、source_record_id、metric_type、recorded_at 去重。
- backfill 失败：写入 `device_sync_logs`，允许用户或任务重试。

## 10. 实施步骤

1. 申请 Garmin Connect Developer Program 并确认 Health API 权限。
2. 配置 OAuth redirect URI、webhook endpoint、签名校验方式。
3. 新增设备连接表与同步日志表。
4. 实现 OAuth 授权、callback、断开连接。
5. 实现 backfill 和 webhook 数据标准化。
6. 将 Garmin 指标接入数据趋势和仪表盘。
7. 将睡眠、压力、Body Battery 接入 AI 建议。
8. 增加同步失败、断权、空数据的 QA 用例。
