# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## AI 编程编码规范

你是一个专业的全栈工程师。请严格遵守以下编码规范进行代码生成、修改、重构和评审。

### 1. 总体原则

#### 1.1 代码目标

编写代码时优先考虑：

1. 正确性：功能必须符合需求，边界条件处理清晰。
2. 可读性：代码应易于理解，命名清晰，结构简单。
3. 可维护性：避免过度设计，但要保持模块边界清楚。
4. 安全性：默认防范常见安全问题。
5. 性能合理：避免明显低效实现，但不要过早优化。
6. 一致性：遵循项目现有风格，优先保持与当前代码一致。

#### 1.2 修改原则

- 优先修改现有代码，不要随意创建新文件、新抽象或新框架。
- 不要为假设中的未来需求提前设计复杂架构。
- 不要重构与当前任务无关的代码。
- 不要引入未请求的新功能。
- 不要破坏现有 API、数据结构、配置和测试，除非任务明确要求。
- 如果发现安全漏洞、明显 bug 或数据不一致，应主动修复或指出。

### 2. 命名与代码风格

#### 2.1 命名原则

命名必须表达业务含义，而不是实现细节。

推荐：

```ts
const activeUsers = users.filter(user => user.status === 'active');
```

避免：

```ts
const arr2 = arr.filter(x => x.s === 'active');
```

#### 2.2 常见命名规范

**变量与函数**

- 使用清晰的动宾结构或业务语义。
- 变量使用名词或名词短语。
- 函数使用动词或动宾短语。

```ts
const userProfile = await getUserProfile(userId);

function calculateTotalPrice(items: OrderItem[]): number {
  // ...
}
```

**布尔值**

布尔变量应使用明确前缀：

- `is`
- `has`
- `can`
- `should`
- `allow`
- `enabled`

```ts
const isAuthenticated = true;
const hasPermission = false;
const shouldRetry = retryCount < maxRetries;
```

避免：

```ts
const auth = true;
const permission = false;
```

**数组**

数组名应使用复数或集合语义：

```ts
const users = [];
const orderItems = [];
const enabledFeatures = [];
```

**常量**

全局常量使用大写蛇形命名：

```ts
const MAX_RETRY_COUNT = 3;
const DEFAULT_PAGE_SIZE = 20;
```

局部不可变变量仍使用普通 `camelCase`：

```ts
const defaultPageSize = 20;
```

**类与类型**

类、接口、类型使用 `PascalCase`：

```ts
class UserService {}

interface UserProfile {}

type PaymentStatus = 'pending' | 'paid' | 'failed';
```

**文件命名**

根据技术栈选择一致风格，常见推荐：

- 前端组件：`UserProfileCard.tsx`
- 普通工具文件：`date-utils.ts`
- 后端服务文件：`user.service.ts`
- DTO / 类型文件：`create-user.dto.ts`
- 测试文件：`user.service.spec.ts`

不要在同一项目中混用多种文件命名风格。

### 3. 代码风格

#### 3.1 保持函数短小

函数应只做一件清晰的事情。

推荐：

```ts
function getDiscountedPrice(price: number, discountRate: number): number {
  return price * (1 - discountRate);
}
```

避免：

```ts
function processOrder(order: Order) {
  // 校验订单
  // 计算价格
  // 更新库存
  // 发送邮件
  // 写入日志
  // 推送通知
}
```

如果函数承担多个业务步骤，应拆分为清晰的私有函数或服务方法。

#### 3.2 减少嵌套

优先使用提前返回，避免深层嵌套。

推荐：

```ts
function getUserDisplayName(user?: User): string {
  if (!user) return 'Guest';
  if (!user.name) return 'Unnamed User';

  return user.name;
}
```

避免：

```ts
function getUserDisplayName(user?: User): string {
  if (user) {
    if (user.name) {
      return user.name;
    } else {
      return 'Unnamed User';
    }
  } else {
    return 'Guest';
  }
}
```

#### 3.3 避免魔法值

重要数字、字符串应提取为有意义的常量。

```ts
const PASSWORD_MIN_LENGTH = 8;

if (password.length < PASSWORD_MIN_LENGTH) {
  throw new Error('Password is too short');
}
```

#### 3.4 避免重复代码

- 重复 2 次可以接受。
- 重复 3 次以上应考虑抽取。
- 不要为了消除轻微重复而制造复杂抽象。

#### 3.5 类型明确

在 TypeScript、Java、Go、Rust、C# 等强类型语言中：

- 公共函数必须声明参数和返回类型。
- 避免使用 `any`。
- 不要用类型断言掩盖真实类型问题。
- 优先使用明确的领域类型。

```ts
function createUser(input: CreateUserInput): Promise<User> {
  // ...
}
```

避免：

```ts
function createUser(input: any): any {
  // ...
}
```

### 4. 注释与文档

#### 4.1 注释原则

注释应该解释「为什么」，而不是重复「做了什么」。

推荐：

```ts
// Payment provider may send duplicate webhooks, so this operation must be idempotent.
await markPaymentAsProcessed(paymentId);
```

避免：

```ts
// Set user name
user.name = name;
```

#### 4.2 什么时候需要注释

以下情况应添加简短注释：

- 业务规则不直观。
- 存在历史兼容逻辑。
- 有安全、性能或事务边界方面的特殊原因。
- 使用了不明显的算法或 workaround。
- 外部系统行为与常识不一致。

#### 4.3 什么时候不要写注释

不要写以下注释：

```ts
// Loop through users
for (const user of users) {}

// Return result
return result;

// This function gets user by id
function getUserById(id: string) {}
```

如果代码需要大量注释才能理解，优先重命名变量、拆分函数或调整结构。

#### 4.4 文档规范

需要文档的内容包括：

- 项目启动方式。
- 环境变量说明。
- API 使用方式。
- 数据库迁移方式。
- 部署步骤。
- 重要架构决策。
- 常见故障排查。

文档应保持简洁、可执行、与代码同步。

### 5. 项目结构与架构

#### 5.1 通用目录结构

全栈项目推荐结构：

```text
project-root/
  apps/
    web/
    mobile/
    backend/
  packages/
    shared/
    config/
    ui/
  docs/
  scripts/
  tests/
  README.md
```

单体项目推荐结构：

```text
src/
  modules/
  common/
  config/
  infrastructure/
  utils/
  tests/
```

#### 5.2 模块边界

每个模块应围绕业务能力组织，而不是单纯按技术类型堆叠。

推荐：

```text
src/
  modules/
    user/
      user.controller.ts
      user.service.ts
      user.repository.ts
      user.types.ts
    order/
      order.controller.ts
      order.service.ts
      order.repository.ts
      order.types.ts
```

不推荐大型项目长期使用：

```text
src/
  controllers/
  services/
  repositories/
  models/
```

#### 5.3 分层职责

**Controller / Route / Handler**

负责：

- 接收请求。
- 参数解析。
- 权限边界。
- 调用 service。
- 返回响应。

不应负责：

- 复杂业务逻辑。
- 数据库 SQL。
- 第三方 API 细节。

**Service / Use Case**

负责：

- 业务规则。
- 流程编排。
- 事务边界。
- 调用 repository 或外部服务。

不应负责：

- HTTP 请求细节。
- UI 展示逻辑。
- 直接拼接 SQL，除非项目约定如此。

**Repository / DAO**

负责：

- 数据库读写。
- ORM 查询。
- SQL 映射。
- 数据持久化细节。

不应负责：

- 业务决策。
- 权限判断。
- HTTP 响应处理。

**Frontend Component**

负责：

- UI 展示。
- 用户交互。
- 调用状态管理或 API client。

不应负责：

- 复杂业务计算。
- 直接拼接后端 URL 逻辑。
- 重复实现后端校验规则。

#### 5.4 依赖方向

依赖应单向流动：

```text
Controller -> Service -> Repository -> Database
UI -> Hooks/Store -> API Client -> Backend
```

禁止反向依赖：

```text
Repository -> Service
Service -> Controller
Common -> Business Module
```

#### 5.5 配置管理

- 配置必须从环境变量或配置文件读取。
- 不要在代码中硬编码密钥、Token、数据库地址、云服务凭证。
- 环境变量应有示例文件，如 `.env.example`。
- 不要提交真实 `.env` 文件。

### 6. API 设计规范

#### 6.1 REST API

推荐使用资源语义：

```text
GET    /users
GET    /users/:id
POST   /users
PATCH  /users/:id
DELETE /users/:id
```

避免动作式 URL：

```text
POST /getUser
POST /createUser
POST /deleteUser
```

特殊业务动作可以使用子资源：

```text
POST /orders/:id/cancel
POST /users/:id/reset-password
```

#### 6.2 请求与响应

请求和响应字段命名应保持一致。

前端和 API 推荐使用 `camelCase`：

```json
{
  "userId": "123",
  "displayName": "Alice"
}
```

数据库字段可使用 `snake_case`：

```text
user_id
display_name
created_at
```

字段映射应集中在 repository、mapper 或 serializer 中。

#### 6.3 错误响应

错误响应应结构统一：

```json
{
  "code": "USER_NOT_FOUND",
  "message": "User not found",
  "details": {}
}
```

不要直接暴露数据库错误、堆栈信息或内部实现细节。

### 7. 前端规范

#### 7.1 组件设计

组件应分为：

- 页面组件：负责页面级数据组织。
- 业务组件：负责具体业务展示。
- 基础组件：按钮、输入框、弹窗等通用 UI。
- Hook / Store：负责状态和副作用。
- API Client：负责请求后端。

示例：

```text
src/
  pages/
  components/
  features/
  hooks/
  stores/
  api/
  utils/
```

#### 7.2 状态管理

优先级：

1. 组件局部状态。
2. URL 状态。
3. 页面级状态。
4. 全局状态。

不要把所有状态都放进全局 store。

#### 7.3 表单处理

- 用户输入必须校验。
- 前端校验用于体验，后端校验用于安全。
- 错误信息应清晰可理解。
- 提交按钮应处理 loading 和重复提交。

#### 7.4 UI 交互

- 所有异步操作应有 loading 状态。
- 所有失败场景应有错误提示。
- 重要危险操作应二次确认。
- 空数据状态应有友好展示。
- 列表应考虑分页、搜索或懒加载。

### 8. 后端规范

#### 8.1 参数校验

所有外部输入必须校验：

- HTTP body。
- Query 参数。
- Path 参数。
- Header。
- 文件上传。
- Webhook payload。
- 第三方 API 返回值。

#### 8.2 权限控制

- 认证和授权必须在明确边界完成。
- 用户只能访问自己有权限的数据。
- 不要信任前端传入的 `userId`。
- 当前用户身份应来自 session、JWT 或服务端上下文。
- 管理员接口必须单独校验权限。

#### 8.3 数据访问

- 禁止 SQL 注入。
- 使用参数化查询或 ORM 安全 API。
- 不要拼接用户输入到 SQL。
- 数据库事务应只包裹必要操作。
- 批量操作应考虑性能和锁范围。

#### 8.4 日志

日志应记录：

- 关键业务事件。
- 外部服务调用失败。
- 安全相关事件。
- 后台任务异常。

日志不应记录：

- 密码。
- Token。
- 身份证号。
- 银行卡。
- 私密健康数据。
- 其他敏感个人信息。

### 9. 安全规范

#### 9.1 基础安全要求

必须防范：

- SQL 注入。
- XSS。
- CSRF。
- SSRF。
- 命令注入。
- 路径穿越。
- 任意文件上传。
- 敏感信息泄露。
- 越权访问。
- 不安全反序列化。

#### 9.2 密码与凭证

- 密码必须使用安全哈希算法，如 bcrypt、argon2。
- 不要明文存储密码。
- 不要把 Token 写入日志。
- 不要把密钥提交到 Git。
- 不要在前端代码中暴露后端密钥。
- API Key 应通过环境变量注入。

#### 9.3 输入输出处理

- 输入必须校验。
- 输出到 HTML 前必须转义。
- 文件路径必须限制在允许目录内。
- URL 请求必须限制协议和目标域名，防止 SSRF。
- 上传文件必须校验类型、大小和扩展名。

#### 9.4 权限与数据隔离

- 后端必须根据当前登录用户判断数据归属。
- 多租户系统必须校验 `tenantId`。
- 管理员权限不能只依赖前端控制。
- 删除、导出、修改敏感数据必须做权限检查。

### 10. 性能规范

#### 10.1 通用原则

- 不要在循环中执行重复数据库查询。
- 避免 N+1 查询。
- 大列表必须分页。
- 大文件应流式处理。
- 避免无意义的深拷贝。
- 避免重复计算昂贵结果。
- 缓存必须有失效策略。

#### 10.2 数据库性能

- 高频查询字段应考虑索引。
- 查询只取需要的字段。
- 避免无条件全表扫描。
- 分页优先使用稳定排序。
- 大批量写入应使用批处理。
- 事务中不要执行慢速外部请求。

#### 10.3 前端性能

- 大组件应拆分。
- 大列表使用虚拟滚动或分页。
- 图片应压缩并懒加载。
- 避免不必要的重复渲染。
- API 请求应避免重复触发。
- 首屏资源应控制体积。

### 11. 测试规范

#### 11.1 测试优先级

至少覆盖：

- 核心业务逻辑。
- 权限边界。
- 数据校验。
- 重要 API。
- 关键 UI 流程。
- 历史 bug 回归场景。

#### 11.2 单元测试

单元测试应：

- 快速。
- 稳定。
- 聚焦单个函数或模块。
- 覆盖正常路径和异常路径。

#### 11.3 集成测试

集成测试应覆盖：

- API 到数据库的完整流程。
- 认证与授权。
- 外部依赖的关键交互。
- 数据一致性。

#### 11.4 测试命名

测试名称应描述行为：

```ts
it('returns current user profile when user is authenticated', async () => {});
it('rejects profile update when user is not authenticated', async () => {});
```

避免：

```ts
it('test user profile', async () => {});
```

### 12. Git 提交规范

#### 12.1 Commit Message 格式

推荐使用 Conventional Commits：

```text
<type>(<scope>): <description>
```

示例：

```text
feat(auth): add refresh token rotation
fix(order): prevent duplicate payment submission
docs(api): update authentication examples
refactor(user): simplify profile update flow
test(payment): add webhook idempotency tests
```

#### 12.2 常用 type

| Type | 用途 |
| --- | --- |
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档修改 |
| style | 格式调整，不影响逻辑 |
| refactor | 重构，不改变行为 |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建、依赖、脚本等杂项 |
| ci | CI/CD 配置 |
| build | 构建系统或依赖变更 |
| revert | 回滚提交 |

#### 12.3 提交要求

- 一个 commit 只做一类事情。
- 不要把格式化、重构、功能、修复混在一个 commit。
- 提交信息应说明意图，而不只是描述文件变化。
- 不要提交密钥、日志、临时文件、构建产物。
- 不要使用无意义提交信息。

避免：

```text
update
fix bug
wip
change files
```

推荐：

```text
fix(auth): reject expired refresh tokens
feat(profile): support avatar upload
docs(setup): clarify local database configuration
```

### 13. Pull Request 规范

#### 13.1 PR 描述应包含

```md
## Summary

- What changed
- Why it changed

## Test Plan

- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual verification

## Risk

- Low / Medium / High
- Potential impact
```

#### 13.2 PR 要求

- PR 应尽量聚焦一个目标。
- 大型改动应拆分为可评审的小步骤。
- 行为变化必须说明。
- 数据库迁移必须说明兼容性和回滚方式。
- UI 改动应附截图或录屏。

### 14. 依赖管理

#### 14.1 添加依赖前必须考虑

- 是否真的需要新依赖？
- 标准库或现有依赖是否已能解决？
- 依赖是否维护活跃？
- 许可证是否可接受？
- 包体积是否影响前端性能？
- 是否存在已知安全漏洞？

#### 14.2 依赖使用原则

- 不要为了很小的功能引入大型依赖。
- 不要引入无人维护的包。
- 不要同时使用多个功能重复的库。
- 锁文件必须提交。
- 升级依赖时应运行测试。

### 15. AI 编程特别要求

当你作为 AI 编程助手修改代码时，必须遵守：

1. 先理解现有代码，再修改。
2. 优先遵循项目已有风格，而不是套用通用模板。
3. 不要臆造不存在的文件、函数、接口或配置。
4. 修改前先搜索相关调用点。
5. 修改 API 时同步更新调用方、类型、测试和文档。
6. 不要留下半成品代码。
7. 不要添加无用注释。
8. 不要吞掉错误。
9. 不要用 `any`、空 `catch`、硬编码、假数据来掩盖问题。
10. 完成后应运行相关测试、类型检查或 lint。
11. 如果无法运行测试，必须明确说明原因。
12. 如果需求不明确，先提问，不要擅自决定关键业务行为。

### 16. 禁止行为

#### 16.1 安全风险

```ts
const sql = `SELECT * FROM users WHERE id = ${userId}`;
```

应改为参数化查询：

```ts
const result = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
```

#### 16.2 空错误处理

```ts
try {
  await doSomething();
} catch (error) {}
```

应至少记录或向上抛出：

```ts
try {
  await doSomething();
} catch (error) {
  logger.error('Failed to do something', error);
  throw error;
}
```

#### 16.3 无意义类型

```ts
function handleData(data: any): any {}
```

应定义明确类型：

```ts
function handleData(data: UserInput): UserResult {}
```

#### 16.4 硬编码密钥

```ts
const apiKey = 'sk_live_xxx';
```

应使用环境变量：

```ts
const apiKey = process.env.API_KEY;
```

#### 16.5 前端伪权限

```ts
if (user.role === 'admin') {
  showDeleteButton();
}
```

这只能控制 UI 展示，后端仍必须校验权限。

### 17. 推荐输出格式

当 AI 完成代码任务时，应输出：

```md
## Changes

- 修改了什么
- 为什么这么改

## Verification

- 运行了哪些测试
- 是否通过

## Notes

- 风险
- 后续建议
```

如果只是小改动，可以简化为：

```text
已完成：修复了 xxx，并通过 xxx 验证。
```

### 18. 最终原则

如果规范与项目现有约定冲突：

1. 优先遵循项目已有代码风格。
2. 其次遵循项目文档。
3. 再遵循本规范。
4. 如果仍不确定，先询问用户。

## Repository shape

This is a health-management monorepo with three active areas:
- `apps/backend`: NestJS API backed by PostgreSQL.
- `apps/mobile`: Flutter client for Android/iOS/Web.
- `packages/shared`: small shared TypeScript types package (`@health/shared`).
- `docs`: product, architecture, API, database, UI, QA, and setup docs. Start with `docs/README.md` for the curated reading order.

The root npm workspace includes `apps/backend` and `packages/shared`. The Flutter app is not part of the npm workspace and is managed separately with Flutter tooling.

## Required project skill

Before planning or implementing HealthGuard features, use the project skill at `.claude/skills/healthguard-development-guidelines/SKILL.md`. It encodes the requirement that development must follow `docs/` design documents, `docs/03-technical/development-plan.md` sprint order, and `UI/` prototypes.

## Common commands

### Root workspace
- `npm install`
- `npm run backend:build`
- `npm run backend:lint`
- `npm run backend:test`

### Backend (`apps/backend`)
- `npm install`
- `npm run start:dev`
- `npm run build`
- `npm run start:prod`
- `npm run lint`
- `npm run test`
- `npm run test:e2e`
- Single test file: `npx jest test/app.e2e-spec.ts --config ./test/jest-e2e.json`
- Single unit test pattern: `npx jest src/<path>/<file>.spec.ts`

### Mobile (`apps/mobile`)
- `flutter pub get`
- `flutter run -d chrome`
- `flutter devices`
- `flutter run -d <deviceId>`
- `flutter analyze`
- `flutter build apk --release`
- `flutter build appbundle --release`

## Environment and runtime

Backend configuration is loaded with `ConfigModule` in `apps/backend/src/app.module.ts`.
- Test runs load `.env.test` first, then `.env`.
- Non-test runs load `.env`.
- The backend listens on `process.env.PORT ?? 3000` in `apps/backend/src/main.ts`.

The backend now depends on PostgreSQL for auth, profiles, diet/exercise records, history, summaries, and dashboard aggregation. E2E tests are integration-style and expect a reachable PostgreSQL instance matching `.env.test`.

For Android emulator runs, the Flutter client defaults `API_BASE_URL` to `http://10.0.2.2:3000`. Override with `--dart-define=API_BASE_URL=...` when the backend is on another port.

## Architecture overview

### Backend

The NestJS app is intentionally thin and follows a consistent flow:
- controllers define REST endpoints and auth boundaries,
- services contain lightweight orchestration and small business rules,
- repositories perform raw SQL queries through `pg`.

Key modules:
- `AuthModule`: phone-code login, current-user lookup, refresh-token flow.
- `HealthModule`: profile CRUD, diet/exercise writes, history reads, daily summary, dashboard.
- `DatabaseModule`: global PostgreSQL pool provider and shutdown cleanup.

Important implementation pattern:
- API fields are camelCase.
- PostgreSQL columns are snake_case.
- Repository methods do the mapping between them.
- Numeric SQL values are normalized back to numbers in repository code before returning upstream.

Current auth/data boundaries matter:
- “current user” resources should use JWT `sub`, not trust caller-supplied `userId`.
- New protected health endpoints should follow the same guard pattern as `/health/profiles/me` and `/health/dashboard/today`.
- Public write endpoints still exist for some record creation flows; docs indicate the direction is to bind all health writes to the authenticated user over time.

### Mobile

The Flutter app is currently a single-file flow in `apps/mobile/lib/main.dart`.
- `AppStage` drives the app through `login -> onboarding -> dashboard`.
- `ApiClient` is the integration seam for backend requests.
- There is not yet a larger page/module split, so backend API additions often require matching request/response additions in this file.

Current startup flow:
1. login via `/auth/login`
2. fetch current profile via `/health/profiles/me`
3. if missing, go to onboarding and submit `/health/profiles/me`
4. otherwise load `/health/dashboard/today`

### Shared package

`packages/shared` currently holds a small set of domain types (`UserProfile`, nutrition-related types). It is lightweight and not a comprehensive contract layer yet.

## Data model and domain context

The current PostgreSQL schema lives in `apps/backend/sql/m1_m2_schema.sql` and includes:
- `users`
- `user_profiles`
- `auth_refresh_tokens`
- `diet_records`
- `exercise_records`

The implemented MVP focus is personal health management: profile, diet, exercise, history, daily summary, and dashboard. Per the docs, “companion context” is an explanatory layer for user health behavior, not a separate pet-health product domain.

## Key docs to trust

When you need product or architecture context, prefer these docs:
- `docs/README.md`: document index and current repo status.
- `docs/00-overview/architecture.md`: system boundaries, module layering, roadmap.
- `docs/03-technical/development-plan.md`: current baseline, iteration priorities, backend/mobile design constraints.
- `docs/setup.md`: local environment and run commands.

Important guidance pulled from docs:
- Current user health data should ultimately be bound to the authenticated user.
- API should stay camelCase while DB remains snake_case.
- Companion context is part of user-health interpretation, not a standalone pet module.

## Testing notes

Backend e2e coverage currently centers on the integrated health flow in `apps/backend/test/app.e2e-spec.ts`: login, profile, diet/exercise writes, history, daily summary, and dashboard. If these tests fail unexpectedly, verify database reachability before assuming the app logic is broken.

When changing backend APIs that the mobile app consumes, run both:
- backend build/e2e checks
- `flutter analyze` in `apps/mobile`
