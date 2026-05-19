# 数据库设计

## 1. 设计目标

数据库需要支撑用户身份、健康档案、健康记录、日汇总、趋势分析、AI 建议、报告、家庭共享和设备接入。当前阶段优先保证 MVP 数据闭环稳定，后续逐步扩展。

## 2. Current 表结构

当前 SQL 草案位于 `apps/backend/sql/m1_m2_schema.sql`。

### `users`

- `id UUID PRIMARY KEY`
- `phone VARCHAR(20) UNIQUE`
- `created_at TIMESTAMPTZ`

### `user_profiles`

- `user_id UUID PRIMARY KEY`
- `nickname`
- `age`
- `gender`
- `height_cm`
- `weight_kg`
- `goal`
- `updated_at`

### `auth_refresh_tokens`

- `user_id UUID PRIMARY KEY`
- `refresh_token`
- `issued_at`

### `diet_records`

- `id UUID PRIMARY KEY`
- `user_id`
- `meal_type`
- `food_name`
- `recorded_on`
- 营养字段：`calories`、`carbs`、`protein`、`fat`、`fiber`、`sodium_mg`、`calcium_mg`、`iron_mg`、`vitamin_a_mcg`、`vitamin_c_mg`、`vitamin_d_iu`
- `created_at`
- 索引：`idx_diet_records_user_date`

### `exercise_records`

- `id UUID PRIMARY KEY`
- `user_id`
- `exercise_type`
- `duration_minutes`
- `calories_burned`
- `recorded_on`
- `created_at`
- 索引：`idx_exercise_records_user_date`

## 3. Current 聚合策略

- 日营养汇总：按 `diet_records.user_id + recorded_on` 聚合营养字段。
- 日运动消耗：按 `exercise_records.user_id + recorded_on` 聚合 `calories_burned`。
- 健康分：由服务层基于蛋白质、膳食纤维、运动消耗、热量平衡计算。
- 仪表盘：组合档案、日汇总、卡片指标和 AI 洞察文案。

## 4. Redis 缓存设计

### Next

Redis 是缓存中间件，不替代 PostgreSQL 表结构。所有健康数据、用户授权、设备 token、同步日志和 AI 建议状态仍以数据库为权威来源。

### Key 命名规范

- 统一前缀：`health:`，系统级短期状态可用 `oauth:`、`lock:`、`rate-limit:`。
- 用户数据 key 必须包含 `userId`。
- 日期统一使用 `YYYY-MM-DD`，时间范围使用 ISO 日期或已规范化的 `from/to`。
- 参数较长时可对规范化参数做 hash，但文档和日志中仍需保留可排查的业务维度。

### 缓存清单

| Key | 内容 | TTL | 来源 | 失效规则 |
|---|---|---|---|---|
| `health:profile:{userId}` | 当前用户档案 | 10 分钟 | `user_profiles` | 档案 upsert |
| `health:profile-center:{userId}` | 我的页聚合资料 | 5 分钟 | 档案、目标、设备、报告 | 档案、设备、报告变化 |
| `health:summary:{userId}:{date}` | 日汇总 | 5 分钟 | 饮食、运动、饮水、睡眠、指标事件 | 对应日期记录变化 |
| `health:dashboard:{userId}:{date}` | 今日仪表盘响应 | 1-2 分钟 | 档案、日汇总、AI 洞察 | 档案或当日数据变化 |
| `health:history:{type}:{userId}:{from}:{to}:{limit}` | 记录历史列表 | 2 分钟 | 各记录表 | 对应类型记录变化 |
| `health:trends:{userId}:{metric}:{period}:{from}:{to}` | 趋势聚合结果 | 10 分钟 | `health_metric_events` / 日汇总 | 指标事件或 backfill 写入 |
| `health:ai:recommendations:{userId}:{date}` | 今日建议列表 | 5 分钟 | `ai_recommendations` / 规则引擎 | 建议动作或指标变化 |
| `health:report:{userId}:{period}:{start}:{end}` | 报告摘要 | 30 分钟 | 汇总、趋势、建议 | 周期内数据变化 |
| `health:device:connections:{userId}` | 设备连接状态 | 5 分钟 | `connected_devices` / `device_sync_logs` | 连接、断开、同步状态变化 |
| `oauth:garmin:state:{state}` | Garmin OAuth state | 10 分钟 | 授权发起流程 | callback 成功或过期 |
| `lock:garmin:sync:{providerUserId}` | 同步分布式锁 | 5-10 分钟 | backfill / webhook | 同步结束或 TTL 过期 |
| `dedupe:garmin:webhook:{eventDigest}` | webhook 去重标记 | 24 小时 | Garmin webhook | TTL 过期 |
| `rate-limit:{scope}:{identifier}` | 登录、验证码、同步限流 | 窗口期 | 业务请求 | TTL 过期 |

### 写入后的失效策略

- 档案更新：删除 `profile`、`profile-center`、当日 `dashboard`。
- 饮食 / 运动 / 饮水 / 睡眠写入：删除对应日期 `summary`、`dashboard`、对应类型 `history`、受影响周期 `trends`、`report` 和 `ai recommendations`。
- 手动指标写入：删除对应指标趋势、当日首页、报告和 AI 建议缓存。
- Garmin backfill / webhook：按写入指标的用户、日期范围、指标类型删除趋势、首页、报告、AI 建议和设备连接状态缓存。
- AI 建议动作：删除或更新当日建议缓存。
- 报告重新生成：删除同周期报告缓存。

### 降级与一致性

- 缓存读取失败：跳过缓存，继续查询 PostgreSQL。
- 缓存写入失败：返回业务结果，并记录 warning。
- 缓存失效失败：不回滚数据库事务，但需要暴露日志和后续重试观察点。
- 首期采用主动删除 + 短 TTL 保证最终一致，不引入复杂的缓存索引表。
- Redis 不保存 Garmin token、refresh token 明文、诊疗级敏感信息或报告文件本体。

## 5. Next 推荐表

### `water_records`

用于饮水记录和饮水趋势。

- `id`
- `user_id`
- `amount_ml`
- `recorded_at`
- `source`
- `created_at`

### `sleep_records`

用于睡眠记录和睡眠建议。

- `id`
- `user_id`
- `sleep_start`
- `sleep_end`
- `duration_minutes`
- `sleep_score`
- `source`
- `created_at`

### `medication_reminders`

用于用药提醒。

- `id`
- `user_id`
- `medicine_name`
- `dosage`
- `schedule_rule`
- `enabled`
- `created_at`
- `updated_at`

### `health_metric_events`

统一承载体重、心率、血压、血糖、Garmin 同步指标等事件，方便趋势扩展。

- `id`
- `user_id`
- `metric_type`
- `value`
- `unit`
- `recorded_at`
- `source`
- `source_record_id`
- `metadata`
- `created_at`

Garmin 常见 `metric_type` 映射方向：

| Garmin 数据 | `metric_type` | 单位 |
|---|---|---|
| steps | `steps` | `count` |
| heart rate | `heart_rate` | `bpm` |
| resting heart rate | `resting_heart_rate` | `bpm` |
| sleep | `sleep_duration` / `sleep_score` | `minutes` / `score` |
| stress | `stress` | `score` |
| pulse ox | `pulse_ox` | `%` |
| Body Battery | `body_battery` | `score` |
| calories | `calories_burned` | `kcal` |
| intensity minutes | `intensity_minutes` | `minutes` |

### `ai_recommendations`

用于建议展示、采纳、忽略和效果追踪。

- `id`
- `user_id`
- `type`
- `title`
- `reason`
- `action_text`
- `status`
- `generated_on`
- `created_at`
- `updated_at`

### `health_reports`

用于报告生成、导出和分享。

- `id`
- `user_id`
- `period_type`
- `period_start`
- `period_end`
- `summary`
- `file_url`
- `status`
- `created_at`

## 6. Future 表方向

### Garmin / 设备接入

Next 阶段优先把 Garmin 接入落在以下表上：

- `connected_devices`：设备授权关系。
- `device_sync_logs`：同步任务、回调、补拉、失败重试记录。
- `device_metric_mappings`：厂商字段到内部 `metric_type` 的映射。
- `health_metric_events`：最终进入业务分析的标准化指标事件。

`connected_devices` 建议字段：

- `id`
- `user_id`
- `provider`，首个值为 `garmin`
- `provider_user_id`
- `access_token_encrypted`
- `refresh_token_encrypted`
- `scopes`
- `status`
- `last_synced_at`
- `created_at`
- `updated_at`

`device_sync_logs` 建议字段：

- `id`
- `user_id`
- `connected_device_id`
- `provider`
- `sync_type`：`oauth_callback`、`webhook`、`backfill`、`manual`
- `status`：`pending`、`success`、`failed`
- `started_at`
- `finished_at`
- `error_code`
- `error_message`
- `raw_payload_digest`

Redis 在 Garmin 接入中只承担 OAuth state、同步锁、webhook 去重和连接状态短缓存；`connected_devices` 与 `device_sync_logs` 仍是排查授权和同步问题的权威记录。

### 家庭共享

- `family_groups`
- `family_members`
- `sharing_permissions`
- `sharing_audit_logs`

核心要求：所有共享数据必须可撤销、可审计，并按授权范围过滤。

### 多厂商设备生态

- `connected_devices`
- `device_sync_logs`
- `device_metric_mappings`

核心要求：设备数据必须保留来源、同步时间和去重标识。

### Pro 会员

- `subscriptions`
- `entitlements`
- `expert_service_orders`

核心要求：权益控制应和报告、AI 深度建议、家庭高级共享解耦。

## 7. Companion Context 持久化边界

如需持久化 companion context，推荐以用户上下文记录承载：

- `companion_context_records`
- `companion_context_daily_summaries`

字段、评分范围和摘要语义以 [../reference/companion-context.md](../reference/companion-context.md) 为准。不得引入宠物病历、疫苗、用药、诊断等宠物健康表。

## 8. 迁移建议

- 短期保留当前 SQL 草案作为第一阶段 schema。
- 后续按模块新增迁移，避免一次性创建远期所有表。
- 对 `user_id + recorded_on/recorded_at` 高频查询建立复合索引。
- 数值指标使用 `NUMERIC` 或明确精度，趋势查询可按日物化汇总。
- Redis 引入不需要数据库迁移，但需要在部署环境新增 Redis 实例、连接配置、健康检查和监控指标。
