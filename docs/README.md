# HealthGuard 文档中心

本目录是 HealthGuard 健康管理应用的产品、研发与测试协作文档中心。文档按“概览 -> 产品 -> 功能 -> 技术 -> UI -> QA -> 参考规范”组织，并用状态标签区分当前实现与后续规划。

## 状态标签

- `Current`：当前代码已经实现或已经有明确 SQL / DTO / UI 原型支撑。
- `Next`：近期建议开发，文档会写到业务规则、接口方向、数据对象、页面状态与验收标准。
- `Future`：远期模块方向，仅定义业务边界、模块拆分、关键对象和集成方向，不作为当前实现承诺。

## 全局规则

- 后续所有开发默认必须支持多语言，不得新增仅中文硬编码的用户可见文案。
- 首期支持 `zh-Hans`、`zh-Hant`、`en`、`ja`、`ko`；新增语言按国际化方案扩展。
- 如确有不可翻译的临时占位内容，必须在进入实现前补齐翻译或明确标记为 Future 并获得确认。
- 用户语言偏好、API locale、缓存 key 和生成类内容必须保持一致。

## 阅读路径

### 产品与业务

1. [产品业务方案](./01-product/business-plan.md)
2. [功能规格说明](./02-features/feature-spec.md)
3. [移动端 UI 设计](./04-ui/mobile-ui-design.md)
4. [Web UI 设计](./04-ui/web-ui-design.md)

### 研发与架构

1. [系统架构](./00-overview/architecture.md)
2. [API 设计](./03-technical/api-design.md)
3. [数据库设计](./03-technical/database-design.md)
4. [开发设计与迭代计划](./03-technical/development-plan.md)
5. [我的模块技术开发方案](./03-technical/profile-center-development.md)
6. [基本信息开发设计方案](./03-technical/basic-profile-development.md)
7. [健康档案 / 用药管理 / 体检报告开发方案](./03-technical/health-profile-subfeatures-development.md)
8. [国际化开发设计方案](./03-technical/i18n-development.md)
9. [Garmin 设备接入设计](./03-technical/garmin-integration.md)

### 测试与验收

1. [验收与测试计划](./05-qa/acceptance-and-test-plan.md)
2. [项目启动指南](./setup.md)

### 参考规范

- [Companion Context / 陪伴上下文规范](./reference/companion-context.md)

## 当前仓库概况

- 后端：NestJS API，已覆盖认证、用户档案、饮食记录、运动记录、记录历史、日汇总与今日仪表盘。
- 移动端：Flutter 客户端，当前代码主流程覆盖登录、首次建档、仪表盘展示。
- 数据层：PostgreSQL SQL 草案与 Repository 已覆盖用户、档案、refresh token、饮食记录、运动记录。
- 缓存层：Next 阶段引入 Redis 作为缓存中间件，承担热点读缓存、OAuth state、限流、Garmin 同步锁和 webhook 去重；PostgreSQL 仍是健康数据权威存储。
- 国际化：Next 阶段支持 `zh-Hans`、`zh-Hant`、`en`、`ja`、`ko`，并以资源文件和 locale allowlist 支持后续扩展。
- UI 原型：`UI/` 目录包含 App 主流程、数据趋势、AI 建议、我的页、基本信息编辑页、健康档案扩展页、语言设置页，以及 Web 工作台原型。

## 阶段路线

- Phase 1 MVP：登录、建档、饮食/运动记录、日汇总、首页仪表盘。
- Phase 2 近期增强：数据趋势、AI 建议、饮水/睡眠/用药、报告导出、个人中心完善、国际化、Redis 热点缓存。
- Phase 3 智能化：AI 饮食识别、自然语言记录、周报/月报、companion context 汇总。
- Phase 4 家庭与设备生态：家庭共享、Garmin 等可穿戴设备接入、医生/健康顾问视图、设备同步锁与去重。
- Phase 5 商业化：Pro 会员、深度报告、专家服务、组织管理端。

## 建议开发周期

- 主版本周期：14 周，覆盖主路径强化、底部导航、数据趋势、AI 建议、报告 MVP、Garmin 接入一期。
- 扩展周期：第 15-18 周，推进家庭共享、Pro 权益和多厂商设备预留。
- 详细排期和每周任务拆解见 [开发设计与迭代计划](./03-technical/development-plan.md)。
