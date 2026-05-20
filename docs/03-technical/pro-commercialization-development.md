# Pro 会员与商业化开发设计方案

## 1. 模块定位

Pro 会员用于承接深度报告、AI 个性化计划、家庭高级共享和专家服务。商业化必须以“增强复盘和协作”为核心，不把基础健康记录、基础趋势、基础安全提醒做成付费门槛。

状态：`Future`，建议在报告 MVP 和家庭共享一期稳定后启动。

## 2. 业务方案

### 套餐分层

| 套餐 | 用户价值 | 包含能力 |
|---|---|---|
| Free | 完成日常记录与基础复盘 | 基础记录、基础趋势、规则型 AI 建议、基础报告 |
| Pro | 更深入的周期复盘和计划 | 深度 AI 报告、目标偏离分析、长期趋势、家庭高级共享 |
| Pro Plus | 引入人工服务 | 专家服务入口、报告解读、个性计划复核 |

### 付费权益

- 深度周报/月报：更长周期、多指标相关性、目标完成解释。
- AI 个性化计划：饮食、运动、睡眠、饮水组合建议。
- 高级家庭共享：更多成员、更多 scope、长期报告共享。
- 设备生态增强：多设备数据源统一分析。
- 专家服务：健康顾问查看用户授权报告并留言。

### 降级策略

- 到期后保留历史报告，但深度分析内容进入只读限制。
- 不删除用户数据，不影响基础记录和基础报告。
- Pro 专属目标和提醒降级为基础目标，不自动删除。
- 家庭高级共享超出 Free 限额时保留成员关系，但暂停超额成员访问。

## 3. 权益模型

### Entitlement

权益判断不直接依赖套餐名，而使用权益 key：

| 权益 key | 说明 |
|---|---|
| `deep_report` | 深度报告 |
| `ai_plan` | AI 个性化计划 |
| `family_advanced` | 家庭高级共享 |
| `multi_device_analysis` | 多设备综合分析 |
| `expert_consultation` | 专家服务 |
| `report_export_pdf` | PDF 导出 |

权益来源可以是订阅、活动赠送、组织分配或人工补偿。

## 4. 支付与订阅流程

```text
用户选择套餐
  -> 创建 checkout session
  -> 支付渠道返回支付结果
  -> webhook 验签
  -> 创建 subscription / invoice / entitlement
  -> 刷新用户权益缓存
  -> App/Web 展示 Pro 状态
```

首期建议先做支付渠道抽象，不把业务逻辑绑定到某个支付服务。

## 5. 数据库设计

所有表必须包含 `created_at`、`updated_at`。

| 表 | 说明 |
|---|---|
| `products` | 商业产品，如 Pro 月付、Pro 年付 |
| `plans` | 套餐定义、价格、周期、状态 |
| `subscriptions` | 用户订阅状态 |
| `subscription_events` | 订阅生命周期事件 |
| `entitlements` | 用户权益明细 |
| `payments` | 支付订单 |
| `invoices` | 账单记录 |
| `expert_service_orders` | 专家服务订单 |

关键字段：

- `subscriptions.status`：`trialing`、`active`、`past_due`、`canceled`、`expired`。
- `entitlements.source_type`：`subscription`、`promo`、`organization`、`manual`。
- `entitlements.expires_at`：权益到期时间。
- `payments.provider`：支付渠道。
- `payments.provider_order_id`：渠道订单号。

## 6. API 设计

| 接口 | 说明 |
|---|---|
| `GET /commerce/products` | 可购买套餐 |
| `GET /commerce/me/entitlements` | 当前用户权益 |
| `POST /commerce/checkout-sessions` | 创建支付会话 |
| `POST /commerce/webhooks/:provider` | 支付 webhook |
| `GET /commerce/subscription/me` | 当前订阅 |
| `POST /commerce/subscription/cancel` | 取消续费 |
| `GET /commerce/invoices/me` | 账单列表 |
| `POST /expert/orders` | 创建专家服务订单 |

权益校验建议提供内部服务：

```text
EntitlementService.has(userId, "deep_report")
EntitlementService.assert(userId, "expert_consultation")
```

## 7. 缓存与一致性

- 用户权益缓存：`commerce:entitlements:{userId}`，TTL 5 分钟。
- 订阅状态变更、支付成功、退款、人工补偿后立即失效缓存。
- 支付 webhook 必须幂等，使用 provider event id 去重。
- 权益服务不可用时，核心免费功能不受影响，Pro 功能展示降级提示。

## 8. UI 原型

### App

已有原型：`UI/app-pro-ecosystem.svg`。

App 侧重点：

- 会员状态。
- 权益列表。
- 深度报告入口。
- 专家服务入口。
- 到期和降级提示。

### Web

新增原型：`UI/web-pro-ecosystem.svg`。

Web 侧重点：

- 套餐对比。
- 订阅状态和账单。
- 权益开关。
- 深度报告和专家服务工作流。

## 9. 验收标准

- Free 用户访问 Pro 功能时能看到明确权益提示。
- Pro 用户能访问深度报告和高级共享能力。
- 订阅到期或取消后权益按规则降级。
- 支付 webhook 重复发送不会重复开通权益。
- 权益、支付、订阅表均具备 `created_at`、`updated_at`。
