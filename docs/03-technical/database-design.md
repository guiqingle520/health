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

## 4. Next 推荐表

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

## 5. Future 表方向

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

## 6. Companion Context 持久化边界

如需持久化 companion context，推荐以用户上下文记录承载：

- `companion_context_records`
- `companion_context_daily_summaries`

字段、评分范围和摘要语义以 [../reference/companion-context.md](../reference/companion-context.md) 为准。不得引入宠物病历、疫苗、用药、诊断等宠物健康表。

## 7. 迁移建议

- 短期保留当前 SQL 草案作为第一阶段 schema。
- 后续按模块新增迁移，避免一次性创建远期所有表。
- 对 `user_id + recorded_on/recorded_at` 高频查询建立复合索引。
- 数值指标使用 `NUMERIC` 或明确精度，趋势查询可按日物化汇总。
