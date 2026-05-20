# 组织管理端 / 运营后台开发设计方案

## 1. 模块定位

组织管理端用于 HealthGuard 内部运营、客服、内容、商业化和专家服务管理。后台不是普通用户健康数据浏览器，默认不允许运营人员查看用户原始健康记录；涉及用户数据的操作必须有权限、原因和审计日志。

状态：`Future`，建议在 Pro、专家服务和报告模板进入开发前启动后台骨架。

## 2. 业务方案

### 管理范围

| 模块 | 说明 |
|---|---|
| 用户管理 | 查询账号状态、登录风险、订阅状态、基础支持信息 |
| 报告模板 | 管理周报/月报模板、字段开关、版本发布 |
| AI 建议模板 | 管理规则型建议和安全提示模板 |
| Pro 权益 | 套餐、权益、人工补偿、活动码 |
| 专家服务 | 专家账号、服务订单、反馈记录 |
| 内容管理 | FAQ、帮助中心、隐私政策版本 |
| 审计日志 | 查看后台操作、敏感数据访问和授权变更 |

### 角色权限

| 角色 | 能力 |
|---|---|
| `admin_owner` | 全部后台配置和角色管理 |
| `support` | 用户支持、订单状态、不能查看健康明细 |
| `content_ops` | 报告模板、FAQ、AI 模板 |
| `commerce_ops` | 商品、套餐、权益、账单 |
| `care_ops` | 专家账号和服务订单 |
| `auditor` | 只读审计日志 |

## 3. 数据访问原则

- 默认展示脱敏信息。
- 查看敏感数据需要二次确认和原因。
- 后台导出必须有权限，并写入导出审计。
- 不能通过后台直接修改用户健康记录。
- 人工补偿权益必须保留操作者、原因、有效期。

## 4. 数据库设计

所有表必须包含 `created_at`、`updated_at`。

| 表 | 说明 |
|---|---|
| `admin_users` | 后台账号 |
| `admin_roles` | 后台角色 |
| `admin_role_permissions` | 角色权限 |
| `admin_audit_logs` | 后台操作日志 |
| `report_templates` | 报告模板 |
| `report_template_versions` | 模板版本 |
| `ai_content_templates` | AI 建议和安全提示模板 |
| `promotion_codes` | 活动码 |
| `manual_entitlement_grants` | 人工权益补偿 |
| `support_tickets` | 客服工单 |

## 5. API 设计

后台 API 建议统一前缀 `/admin`，并使用独立 `AdminAuthGuard`。

| 接口 | 说明 |
|---|---|
| `GET /admin/users` | 用户列表 |
| `GET /admin/users/:id/support-summary` | 用户支持摘要 |
| `GET /admin/report-templates` | 报告模板列表 |
| `POST /admin/report-templates` | 创建模板 |
| `POST /admin/report-templates/:id/publish` | 发布模板版本 |
| `GET /admin/ai-templates` | AI 模板列表 |
| `PUT /admin/ai-templates/:id` | 更新模板 |
| `GET /admin/commerce/plans` | 套餐配置 |
| `POST /admin/commerce/entitlement-grants` | 人工发放权益 |
| `GET /admin/audit-logs` | 审计日志 |

## 6. UI 原型

新增原型：`UI/web-admin-operations.svg`。

页面结构：

- 左侧后台导航：用户、报告模板、AI 模板、Pro 权益、专家服务、审计。
- 主区展示运营指标、待处理事项和最近操作。
- 表格以状态、操作者、更新时间为核心列。
- 敏感操作使用确认弹层和原因输入。

## 7. 验收标准

- 不同后台角色只能看到授权菜单和操作。
- 敏感操作必须写入 `admin_audit_logs`。
- 报告模板支持草稿、发布、停用。
- 人工权益补偿能被用户权益服务识别。
- 后台相关表均具备 `created_at`、`updated_at`。
