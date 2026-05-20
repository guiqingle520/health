# 多厂商设备生态开发设计方案

## 1. 模块定位

多厂商设备生态用于把 Garmin、Apple Health、Google Fit / Health Connect、华为、小米等来源的数据统一进入 HealthGuard 标准化指标模型。目标是让首页、趋势、AI 建议和报告消费同一套 `health_metric_events`，不被具体设备厂商绑死。

状态：`Future`，Garmin 一期完成后启动。

## 2. 业务方案

### Provider 分层

| Provider | 接入方式 | 首期定位 |
|---|---|---|
| Garmin | 云端 OAuth / webhook / pull | 已有专项方案 |
| Apple Health | iOS 端授权读取 | iOS App 侧同步 |
| Health Connect | Android 端授权读取 | Android 新版统一入口 |
| Google Fit | OAuth / API | 兼容存量 Android 用户 |
| Huawei Health | 厂商账号授权 | 国内 Android 扩展 |
| Xiaomi / Zepp | 厂商账号授权或导入 | 后续评估 |

### 用户体验

- “设备与数据源”展示所有可连接 provider。
- 每个 provider 展示可同步指标、最近同步时间和授权状态。
- 用户可以选择参与趋势分析的默认数据源。
- 手动记录与设备数据并存，报告中显示数据来源。

## 3. 标准化模型

所有设备数据先转换为标准指标事件：

```text
provider raw payload
  -> provider adapter
  -> metric normalizer
  -> health_metric_events
  -> dashboard / trends / AI / reports
```

标准字段：

- `metric_type`：指标类型。
- `value`：数值。
- `unit`：单位。
- `recorded_at`：指标发生时间。
- `source`：`manual`、`garmin`、`apple_health` 等。
- `source_record_id`：厂商原始记录 id。
- `confidence`：数据可信度或合并优先级。

## 4. 冲突与合并

| 场景 | 处理 |
|---|---|
| 同一 provider 重复推送 | 基于 `source_record_id` 幂等 |
| 多 provider 同一指标 | 按用户默认数据源优先 |
| 手动记录与设备数据冲突 | 手动记录优先展示，但保留设备数据 |
| 睡眠跨天 | 使用睡眠开始时间归属夜间周期，报告按结束日统计 |
| 单位不同 | 标准化后入库，原始单位放入 metadata |

## 5. 数据库设计

所有表必须包含 `created_at`、`updated_at`。

| 表 | 说明 |
|---|---|
| `device_providers` | provider 配置和能力 |
| `connected_devices` | 用户设备连接 |
| `device_provider_capabilities` | provider 可同步指标 |
| `device_sync_logs` | 同步任务和结果 |
| `device_metric_mappings` | 厂商指标到内部指标映射 |
| `device_source_preferences` | 用户默认数据源偏好 |
| `health_metric_events` | 标准化指标事件 |

## 6. API 设计

| 接口 | 说明 |
|---|---|
| `GET /health/devices/providers` | 可连接 provider 列表 |
| `GET /health/devices/connections` | 用户连接状态 |
| `POST /health/devices/:provider/connect` | 发起连接 |
| `DELETE /health/devices/:provider` | 断开连接 |
| `POST /health/devices/:provider/sync` | 手动同步 |
| `PUT /health/devices/source-preferences` | 设置默认数据源 |
| `POST /integrations/:provider/webhook` | 设备 webhook |

Provider adapter 必须实现统一接口：

```text
connect()
refreshToken()
backfill()
handleWebhook()
normalizeMetrics()
disconnect()
```

## 7. UI 原型

新增原型：`UI/web-devices-ecosystem.svg`。

Web 端重点：

- provider 状态列表。
- 指标覆盖矩阵。
- 最近同步日志。
- 默认数据源设置。
- 异常同步提示。

App 端可在现有 `UI/app-garmin-connect.svg`、`UI/app-garmin-status.svg` 基础上扩展为 provider 列表。

## 8. 验收标准

- 新增 provider 不需要改动趋势、报告和 AI 消费逻辑。
- 同一 provider 重复数据不会重复入库。
- 用户可以断开任意 provider。
- 手动记录和设备数据能同时展示并标注来源。
- 设备相关表均具备 `created_at`、`updated_at`。
