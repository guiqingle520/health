# 数据库设计

## 1. 设计目标

数据库需要支撑用户身份、健康档案、健康记录、日汇总、趋势分析、AI 建议、报告、家庭共享和设备接入。当前阶段优先保证 MVP 数据闭环稳定，后续逐步扩展。

统一时间字段约定：

- 所有业务主表默认包含 `created_at` 和 `updated_at`。
- `recorded_on` / `recorded_at` 只表示业务发生日期或时间，不替代审计字段。

## 2. Current 表结构

当前 SQL 草案位于 `apps/backend/sql/m1_m2_schema.sql`。

### `users`

- `id UUID PRIMARY KEY`
- `phone VARCHAR(20) UNIQUE`
- `created_at TIMESTAMPTZ`
- `updated_at TIMESTAMPTZ`

### `user_profiles`

- `user_id UUID PRIMARY KEY`
- `nickname`
- `age`
- `gender`
- `height_cm`
- `weight_kg`
- `goal`
- `created_at`
- `updated_at`

### `auth_refresh_tokens`

- `user_id UUID PRIMARY KEY`
- `refresh_token`
- `created_at`
- `updated_at`

### `diet_records`

- `id UUID PRIMARY KEY`
- `user_id`
- `meal_type`
- `food_name`
- `recorded_on`
- 营养字段：`calories`、`carbs`、`protein`、`fat`、`fiber`、`sodium_mg`、`calcium_mg`、`iron_mg`、`vitamin_a_mcg`、`vitamin_c_mg`、`vitamin_d_iu`
- `created_at`
- `updated_at`
- 索引：`idx_diet_records_user_date`

### `exercise_records`

- `id UUID PRIMARY KEY`
- `user_id`
- `exercise_type`
- `duration_minutes`
- `calories_burned`
- `recorded_on`
- `created_at`
- `updated_at`
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
- `updated_at`

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
- `updated_at`

### `notification_settings`

用于饮水、运动、睡眠、周报和目标提醒。

- `user_id`
- `water_enabled`
- `exercise_enabled`
- `sleep_enabled`
- `weekly_report_enabled`
- `goal_reminder_enabled`
- `quiet_hours_enabled`
- `quiet_hours_start`
- `quiet_hours_end`
- `created_at`
- `updated_at`

### `health_goals`

用于目标设定和提醒。

- `id`
- `user_id`
- `goal_type`
- `target_value`
- `unit`
- `period`
- `start_date`
- `end_date`
- `reminder_enabled`
- `status`
- `source`
- `created_at`
- `updated_at`

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
- `updated_at`

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
- `updated_at`

### `report_shares`

用于报告分享、医生共享和家人分享。

- `id`
- `report_id`
- `owner_user_id`
- `shared_with_type`
- `shared_with_value`
- `permission`
- `share_token`
- `expires_at`
- `created_at`
- `updated_at`

## 6. 健康档案扩展表

### `health_profile_details`

用于健康档案背景信息。

- `user_id`
- `chronic_diseases` JSONB
- `allergies` JSONB
- `family_history` JSONB
- `exercise_habit`
- `data_sources` JSONB
- `updated_at`

### `medications`

用于药品计划和提醒。

- `id`
- `user_id`
- `name`
- `dosage`
- `frequency`
- `times` JSONB
- `start_date`
- `end_date`
- `reminder_enabled`
- `status`
- `created_at`
- `updated_at`

### `medication_action_logs`

用于记录已服用、稍后和跳过动作。

- `id`
- `user_id`
- `medication_id`
- `action`
- `scheduled_at`
- `acted_at`
- `created_at`

### `exam_reports`

用于体检报告主表。

- `id`
- `user_id`
- `title`
- `exam_date`
- `organization`
- `source`
- `file_url`
- `status`
- `abnormal_count`
- `created_at`
- `updated_at`

### `exam_report_items`

用于体检报告明细指标。

- `id`
- `exam_report_id`
- `user_id`
- `name`
- `value`
- `unit`
- `reference_range`
- `flag`
- `created_at`
- `updated_at`

## 7. 国际化与偏好字段

### `user_preferences`

用于语言、地区和单位偏好。详细方案见 [国际化开发设计方案](./i18n-development.md)。

- `user_id`
- `locale_mode`：`system` / `manual`
- `locale`：`zh-Hans` / `zh-Hant` / `en` / `ja` / `ko`
- `weight_unit`
- `height_unit`
- `energy_unit`
- `updated_at`

旧数据兼容：

- 读取旧值 `zh-CN` 时 normalize 为 `zh-Hans`。
- 读取旧值 `zh-TW`、`zh-HK` 时 normalize 为 `zh-Hant`。
- 写回时统一保存 canonical locale。

## 8. Future 表方向

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
- `created_at`
- `updated_at`

Redis 在 Garmin 接入中只承担 OAuth state、同步锁、webhook 去重和连接状态短缓存；`connected_devices` 与 `device_sync_logs` 仍是排查授权和同步问题的权威记录。

### 家庭共享

- `family_groups`
- `family_members`
- `family_invitations`
- `family_share_permissions`
- `family_access_logs`

核心要求：所有共享数据必须可撤销、可审计，并按授权范围过滤。

详细方案见 [家庭共享完整方案](./family-sharing-development.md)。

### 多厂商设备生态

- `device_providers`
- `connected_devices`
- `device_sync_logs`
- `device_metric_mappings`
- `device_provider_capabilities`
- `device_source_preferences`

核心要求：设备数据必须保留来源、同步时间和去重标识。

详细方案见 [多厂商设备生态开发设计方案](./multi-provider-devices-development.md)。

### Pro 会员

- `products`
- `plans`
- `subscriptions`
- `entitlements`
- `payments`
- `invoices`
- `expert_service_orders`

核心要求：权益控制应和报告、AI 深度建议、家庭高级共享解耦。

详细方案见 [Pro 会员与商业化开发设计方案](./pro-commercialization-development.md)。

### 医生 / 健康顾问视图

- `care_organizations`
- `care_provider_profiles`
- `care_authorizations`
- `care_authorization_scopes`
- `care_notes`
- `care_access_logs`

核心要求：医生/顾问只能访问用户主动授权的数据，所有查看行为必须可审计。

详细方案见 [医生 / 健康顾问视图开发设计方案](./care-provider-workbench-development.md)。

### 组织管理端 / 运营后台

- `admin_users`
- `admin_roles`
- `admin_role_permissions`
- `admin_audit_logs`
- `report_templates`
- `report_template_versions`
- `ai_content_templates`
- `promotion_codes`
- `manual_entitlement_grants`
- `support_tickets`

核心要求：后台操作按角色授权，敏感数据访问必须写入审计日志。

详细方案见 [组织管理端 / 运营后台开发设计方案](./admin-operations-development.md)。

### AI 高阶能力

- `ai_jobs`
- `ai_inputs`
- `ai_outputs`
- `ai_safety_events`
- `food_recognition_results`
- `natural_language_record_drafts`
- `ai_recommendation_reasons`
- `ai_feedback_events`

核心要求：AI 生成结果必须结构化、可解释、可安全审核，并由用户确认后写入正式记录。

详细方案见 [AI 高阶能力开发设计方案](./advanced-ai-development.md)。

### 隐私安全与数据权利

- `privacy_consents`
- `data_export_jobs`
- `account_deletion_requests`
- `authorization_registry`
- `user_access_logs`
- `sensitive_data_access_logs`
- `data_retention_policies`

核心要求：授权撤销后立即失效，数据导出和注销流程可追踪。

详细方案见 [隐私安全与数据权利开发设计方案](./privacy-data-rights-development.md)。

## 9. Companion Context 持久化边界

如需持久化 companion context，推荐以用户上下文记录承载：

- `companion_context_records`
- `companion_context_daily_summaries`

字段、评分范围和摘要语义以 [../reference/companion-context.md](../reference/companion-context.md) 为准。不得引入宠物病历、疫苗、用药、诊断等宠物健康表。

## 10. 迁移建议

- 短期保留当前 SQL 草案作为第一阶段 schema。
- 后续按模块新增迁移，避免一次性创建远期所有表。
- 对 `user_id + recorded_on/recorded_at` 高频查询建立复合索引。
- 数值指标使用 `NUMERIC` 或明确精度，趋势查询可按日物化汇总。
- 新增业务表默认带 `created_at` / `updated_at`，除非是明确例外的纯连接表。
- Redis 引入不需要数据库迁移，但需要在部署环境新增 Redis 实例、连接配置、健康检查和监控指标。
