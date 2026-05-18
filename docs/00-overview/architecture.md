# 系统架构

## 1. 项目定位

HealthGuard 是面向个人与家庭的健康管理应用，核心目标是帮助用户完成“建档、记录、理解、行动、复盘”的健康管理闭环。当前仓库以移动端和后端 API 为主，后续扩展 Web 工作台、AI 分析、报告、家庭共享、设备接入与商业化能力。

## 2. 当前实现状态

### Current

- `apps/mobile`：Flutter 客户端，已实现登录、首次建档、仪表盘主流程。
- `apps/backend`：NestJS API，已实现认证、档案、饮食记录、运动记录、记录历史、日汇总、今日仪表盘。
- `apps/backend/sql/m1_m2_schema.sql`：已包含 `users`、`user_profiles`、`auth_refresh_tokens`、`diet_records`、`exercise_records`。
- `UI/`：已有 App 登录、建档、仪表盘、数据趋势、AI 建议、我的页，以及 Web 登录、建档、仪表盘原型。

### Next

- 移动端从三段式状态机演进为底部导航结构：首页、数据、AI 建议、我的。
- 后端补齐记录日期、鉴权写入、数据趋势、AI 建议、报告导出、个人中心相关接口。
- 数据库补充饮水、睡眠、用药、健康报告、通知提醒、家庭共享、AI 建议记录。

### Future

- 接入 Garmin 等可穿戴设备与第三方健康平台。
- 引入医生 / 健康顾问协作视图。
- 构建 Pro 会员、深度报告、专家服务等商业化能力。

## 3. 架构分层

```text
+----------------------------+
| Flutter Mobile / Web Client |
| login / records / dashboard |
| trends / AI / profile       |
+--------------+-------------+
               |
               | REST JSON + Bearer Token
               v
+----------------------------+
| NestJS Backend              |
| AuthModule                  |
| HealthModule                |
| Future: AI/Report/Family    |
+--------------+-------------+
               |
               | Repository
               v
+----------------------------+
| PostgreSQL                  |
| users / records / summaries |
| future domain tables        |
+----------------------------+
```

## 4. 模块边界

### AuthModule

- Current：手机号验证码登录、JWT access token、refresh token、当前用户解析。
- Next：验证码发送与校验、refresh token 轮换、退出登录、设备会话管理。
- Future：多登录方式、组织账号、医生/顾问身份体系。

### HealthModule

- Current：用户档案、饮食记录、运动记录、日汇总、今日仪表盘、记录历史。
- Next：饮水、睡眠、用药、数据趋势、目标设定、健康报告、Garmin Health API 云端同步。
- Future：健康事件流、设备数据聚合、实时传感流、长期风险评估。

### AI Capability

- Current：后端根据日汇总拼装基础洞察文案。
- Next：AI 建议列表、拍照饮食识别、自然语言记录、建议采纳/忽略。
- Future：个性化计划、周报/月报、医生协作摘要。

### Family / Sharing

- Current：暂无代码实现，UI 原型已体现个人中心入口。
- Next：家人关系、共享范围、邀请与授权。
- Future：家庭健康看板、照护提醒、医生/顾问授权访问。

### Device Integration

- Next：优先接入 Garmin Health API，获取用户授权后同步 Garmin Connect 中的步数、心率、睡眠、压力、血氧、Body Battery 等健康数据。
- Future：如产品需要实时心率、压力或加速度流，再评估 Garmin Health SDK；SDK 适合移动端直连设备，不替代云端历史数据同步。
- Boundary：不使用非官方爬取或模拟 Garmin Connect 登录的方式，避免账号、合规和稳定性风险。

### Companion Context

Companion context 是用户健康分析的解释层，不是独立宠物健康模块。术语、字段与展示边界以 [reference/companion-context.md](../reference/companion-context.md) 为准。

## 5. 核心数据流

### 登录与建档

```text
LoginView
  -> POST /auth/login
  -> GET /health/profiles/me
    -> 404: Onboarding
    -> 200: Dashboard
```

### 记录与汇总

```text
Diet / Exercise Record
  -> POST /health/*-records
  -> aggregate by user + date
  -> GET /health/daily-summary/:userId
  -> GET /health/dashboard/today
```

### 数据趋势

```text
Daily records
  -> daily summaries / metric events
  -> period aggregation
  -> trend chart and anomaly signal
```

### AI 建议

```text
Profile + records + summaries + companion context
  -> rules / AI service
  -> recommendations
  -> user action: accept / dismiss / snooze
```

## 6. 路线图

| 阶段 | 目标 | 重点能力 |
|---|---|---|
| Phase 1 MVP | 跑通健康管理主路径 | 登录、建档、饮食/运动记录、日汇总、仪表盘 |
| Phase 2 近期增强 | 提升记录与复盘效率 | 数据趋势、饮水/睡眠/用药、AI 建议、我的页 |
| Phase 3 智能化 | 提升建议质量 | AI 饮食识别、自然语言记录、周报/月报、companion context |
| Phase 4 家庭与设备 | 扩展协作与数据来源 | 家庭共享、Garmin 设备接入、医生/顾问视图 |
| Phase 5 商业化 | 建立付费能力 | Pro 会员、深度报告、专家服务、组织管理 |

## 7. 建议开发周期

- 第 1 周：项目准备、环境、任务拆分和验收基线。
- 第 2-3 周：登录、建档、首页、鉴权写入主路径强化。
- 第 4-5 周：底部导航、数据、AI 建议、我的页骨架。
- 第 6-9 周：数据趋势、记录增强、AI 建议、报告 MVP。
- 第 10-13 周：Garmin Health API 授权、同步、标准化指标和业务接入。
- 第 14 周：联调、回归、验收、发布准备。
- 第 15-18 周：家庭共享、Pro 权益、多厂商设备预留。
