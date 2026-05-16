# 数据库设计

本文档描述健康管理应用在数据库层的推荐设计，基于当前已存在的 SQL 草案 `apps/backend/sql/m1_m2_schema.sql`，并补充饮食记录、运动记录与仪表盘聚合所需的数据结构。

## 1. 设计目标

数据库设计需要支撑以下核心流程：

- 用户登录与身份识别
- 用户档案维护
- 饮食记录与营养汇总
- 运动记录与热量消耗汇总
- 仪表盘按日聚合
- 后续扩展睡眠、饮水、提醒、AI 分析

## 2. 当前已存在的 SQL 草案

当前仓库已有第一阶段 SQL：`apps/backend/sql/m1_m2_schema.sql`

已定义表：

- `users`
- `user_profiles`
- `auth_refresh_tokens`

这三张表已经覆盖认证和基础建档流程。

## 3. 推荐表结构

### 3.1 用户表

```sql
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  phone VARCHAR(20) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

字段说明：

- `id`：用户唯一标识
- `phone`：手机号，唯一
- `created_at`：注册时间

### 3.2 用户档案表

```sql
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  nickname VARCHAR(50) NOT NULL,
  age INT NOT NULL CHECK (age >= 1 AND age <= 120),
  gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female')),
  height_cm NUMERIC(5, 2) NOT NULL CHECK (height_cm >= 100 AND height_cm <= 250),
  weight_kg NUMERIC(5, 2) NOT NULL CHECK (weight_kg >= 20 AND weight_kg <= 300),
  goal VARCHAR(20) NOT NULL CHECK (goal IN ('lose_fat', 'gain_muscle', 'maintain')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

字段与当前 `UpsertMyProfileDto` / `CreateProfileDto` 对齐。

### 3.3 Refresh Token 表

```sql
CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  refresh_token TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

用途：

- 保存当前有效 refresh token
- 支撑 token 刷新流程

### 3.4 饮食记录表

```sql
CREATE TABLE IF NOT EXISTS diet_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  meal_type VARCHAR(20) NOT NULL,
  food_name VARCHAR(100) NOT NULL,
  recorded_on DATE NOT NULL,
  calories NUMERIC(8, 2) NOT NULL DEFAULT 0,
  carbs NUMERIC(8, 2) NOT NULL DEFAULT 0,
  protein NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fat NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fiber NUMERIC(8, 2) NOT NULL DEFAULT 0,
  sodium_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  calcium_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  iron_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  vitamin_a_mcg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  vitamin_c_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  vitamin_d_iu NUMERIC(8, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

设计依据：

- 与当前 `CreateDietRecordDto` 中的营养字段一一对应
- 支撑 `HealthService.getDailySummary()` 的逐日聚合逻辑

推荐索引：

```sql
CREATE INDEX idx_diet_records_user_date
  ON diet_records (user_id, recorded_on);
```

### 3.5 运动记录表

```sql
CREATE TABLE IF NOT EXISTS exercise_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_type VARCHAR(50) NOT NULL,
  duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
  calories_burned NUMERIC(8, 2) NOT NULL DEFAULT 0,
  recorded_on DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

设计依据：

- 与当前 `CreateExerciseRecordDto` 对齐
- 支撑日消耗热量计算

推荐索引：

```sql
CREATE INDEX idx_exercise_records_user_date
  ON exercise_records (user_id, recorded_on);
```

## 4. 聚合策略

当前代码在 `HealthService` 中即时聚合：

- 汇总当天饮食营养
- 汇总当天运动消耗
- 计算健康分数
- 生成 AI 洞察文案

数据库落地后可采用两种策略：

### 方案 A：实时查询聚合

适合 MVP：

- 查询简单
- 写入逻辑轻量
- 与当前服务实现最接近

### 方案 B：日汇总表或物化视图

适合规模提升后：

```sql
CREATE MATERIALIZED VIEW user_daily_nutrition_summary AS
SELECT
  user_id,
  recorded_on,
  SUM(calories) AS calories,
  SUM(carbs) AS carbs,
  SUM(protein) AS protein,
  SUM(fat) AS fat,
  SUM(fiber) AS fiber
FROM diet_records
GROUP BY user_id, recorded_on;
```

适用场景：

- 仪表盘访问频繁
- 周报 / 月报批量生成
- 日趋势图需要更快查询

## 5. 数据关系

```text
users
  ├─ 1:1 user_profiles
  ├─ 1:1 auth_refresh_tokens
  ├─ 1:N diet_records
  └─ 1:N exercise_records
```

## 6. 与当前代码的对应关系

### 后端代码

- `apps/backend/src/auth`：对应 `users` 与 `auth_refresh_tokens`
- `apps/backend/src/health/dto/create-profile.dto.ts`：对应 `user_profiles`
- `apps/backend/src/health/dto/create-diet-record.dto.ts`：对应 `diet_records`
- `apps/backend/src/health/dto/create-exercise-record.dto.ts`：对应 `exercise_records`
- `apps/backend/src/health/health.service.ts`：对应聚合与仪表盘逻辑

### 当前差距

当前服务层使用内存 `Map` 与数组保存数据，数据库接入时需要将：

- `profiles` Map 替换为 `user_profiles` 查询
- `dietRecords` 数组替换为 `diet_records` 查询
- `exerciseRecords` 数组替换为 `exercise_records` 查询

## 7. 后续扩展建议

后续可以按阶段增加：

- `sleep_records`
- `water_intake_records`
- `medication_records`
- `reminders`
- `ai_insights`
- `report_exports`
- `family_memberships`

建议原则：

- 先保持与当前 DTO 和业务流一致
- 再按功能模块逐步扩表
- 尽量避免一开始设计过于庞大的通用大表
