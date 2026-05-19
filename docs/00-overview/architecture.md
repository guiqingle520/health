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
- 引入 Redis 作为缓存中间件，优先缓存首页仪表盘、日汇总、趋势数据、AI 建议、设备连接状态等热点读结果，并承载 OAuth state、限流计数、同步锁等短期状态。

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
| Cache / AI / Device         |
+------+---------------+------+
       |               |
       | Cache Aside   | Repository
       v               v
+-------------+   +----------------------------+
| Redis       |   | PostgreSQL                  |
| hot reads   |   | users / records / summaries |
| locks/state |   | future domain tables        |
+-------------+   +----------------------------+
```

Redis 只作为缓存和短期协调层，不作为健康数据的权威存储。健康记录、设备 token、同步日志、报告和用户授权关系仍以 PostgreSQL 为准。

## 4. 模块边界

### Cache / Redis

### Next

- 缓存模式：采用 cache-aside。读接口先查 Redis，未命中再查 PostgreSQL / 聚合服务并回填缓存。
- 热点数据：`dashboard/today`、`daily-summary`、`profile-center`、趋势聚合、AI 建议、报告摘要、Garmin 连接状态。
- 短期状态：验证码频控、OAuth state、Garmin backfill / webhook 分布式锁、接口限流计数。
- 失效策略：档案、饮食、运动、饮水、睡眠、指标事件、AI 建议动作、Garmin 同步写入后，删除对应用户和日期范围的缓存。
- 降级策略：Redis 不可用时记录 warning 并走数据库路径；缓存读写失败不得导致业务接口失败。
- 安全边界：不缓存 Garmin access token / refresh token、refresh token 明文、身份证明材料等敏感持久凭据。

### Future

- 根据访问量引入缓存预热、排行榜 / 群组看板局部缓存、报告生成任务状态缓存。
- 如需后台任务队列，可评估 Redis-backed queue，但首期不把 Redis 作为业务事件的唯一队列。

## 5. 模块边界

### AuthModule

- Current：手机号验证码登录、JWT access token、refresh token、当前用户解析。
- Next：验证码发送与校验、refresh token 轮换、退出登录、设备会话管理；Redis 用于验证码频控、登录限流和短期 OAuth state，不保存长期 token。
- Future：多登录方式、组织账号、医生/顾问身份体系。

### HealthModule

- Current：用户档案、饮食记录、运动记录、日汇总、今日仪表盘、记录历史。
- Next：饮水、睡眠、用药、数据趋势、目标设定、健康报告、Garmin Health API 云端同步；Redis 用于热点聚合缓存和写入后的主动失效。
- Future：健康事件流、设备数据聚合、实时传感流、长期风险评估。

### AI Capability

- Current：后端根据日汇总拼装基础洞察文案。
- Next：AI 建议列表、拍照饮食识别、自然语言记录、建议采纳/忽略；Redis 可缓存当日建议和报告摘要，但建议状态以数据库为准。
- Future：个性化计划、周报/月报、医生协作摘要。

### Family / Sharing

- Current：暂无代码实现，UI 原型已体现个人中心入口。
- Next：家人关系、共享范围、邀请与授权。
- Future：家庭健康看板、照护提醒、医生/顾问授权访问。

### Device Integration

- Next：优先接入 Garmin Health API，获取用户授权后同步 Garmin Connect 中的步数、心率、睡眠、压力、血氧、Body Battery 等健康数据。Redis 用于 OAuth state、webhook 去重锁、backfill 同步锁和连接状态短缓存。
- Future：如产品需要实时心率、压力或加速度流，再评估 Garmin Health SDK；SDK 适合移动端直连设备，不替代云端历史数据同步。
- Boundary：不使用非官方爬取或模拟 Garmin Connect 登录的方式，避免账号、合规和稳定性风险。

### Companion Context

Companion context 是用户健康分析的解释层，不是独立宠物健康模块。术语、字段与展示边界以 [reference/companion-context.md](../reference/companion-context.md) 为准。

## 6. 核心数据流

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
  -> invalidate Redis user/date cache
  -> GET /health/daily-summary/:userId
  -> GET /health/dashboard/today
```

### 热点读取缓存

```text
Client
  -> GET dashboard / trends / recommendations
  -> Redis get cache key
    -> hit: return cached response
    -> miss: query PostgreSQL and aggregate
  -> Redis set with TTL
  -> return same API response shape
```

### 数据趋势

```text
Daily records / metric events
  -> Redis cached period aggregation
  -> period aggregation
  -> trend chart and anomaly signal
```

### AI 建议

```text
Profile + records + summaries + companion context
  -> rules / AI service
  -> recommendations
  -> Redis short cache for read list
  -> user action: accept / dismiss / snooze
  -> invalidate / update recommendation cache
```

## 7. 路线图

| 阶段 | 目标 | 重点能力 |
|---|---|---|
| Phase 1 MVP | 跑通健康管理主路径 | 登录、建档、饮食/运动记录、日汇总、仪表盘 |
| Phase 2 近期增强 | 提升记录与复盘效率 | 数据趋势、饮水/睡眠/用药、AI 建议、我的页 |
| Phase 3 智能化 | 提升建议质量 | AI 饮食识别、自然语言记录、周报/月报、companion context |
| Phase 4 家庭与设备 | 扩展协作与数据来源 | 家庭共享、Garmin 设备接入、医生/顾问视图 |
| Phase 5 商业化 | 建立付费能力 | Pro 会员、深度报告、专家服务、组织管理 |

## 8. 建议开发周期

- 第 1 周：项目准备、环境、任务拆分和验收基线。
- 第 2-3 周：登录、建档、首页、鉴权写入主路径强化。
- 第 4-5 周：底部导航、数据、AI 建议、我的页骨架。
- 第 6-9 周：数据趋势、记录增强、AI 建议、报告 MVP。
- 第 10-13 周：Garmin Health API 授权、同步、标准化指标和业务接入。
- 第 14 周：联调、回归、验收、发布准备。
- 第 15-18 周：家庭共享、Pro 权益、多厂商设备预留。
