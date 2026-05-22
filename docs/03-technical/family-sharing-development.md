# 家庭共享完整方案

## 1. 模块定位

家庭共享用于让用户在明确授权下，把部分健康数据分享给家人或照护者。它不是社交关系，也不是医生诊断系统；首期只解决“谁可以看什么、看到多久、撤销后是否立即失效”的问题。

状态：`Future`，建议在主版本稳定后进入第 15-16 周开发。

## 2. 业务方案

### 目标用户

| 角色 | 目标 | 权限边界 |
|---|---|---|
| 共享发起人 | 让家人了解自己的健康趋势和报告 | 可创建家庭、邀请成员、设置共享范围、撤销授权 |
| 家庭成员 | 查看被授权的健康摘要 | 只能看授权范围内的数据，不能修改原始记录 |
| 照护者 | 关注长辈或慢病用户状态 | 需要单独授权，可查看提醒和报告摘要 |
| 被邀请人 | 接收邀请并绑定账号 | 未接受前不可访问任何健康数据 |

### 首期范围

- 创建一个家庭空间。
- 邀请家人加入，支持短信验证码或站内邀请链接。
- 按成员设置共享范围：仪表盘、数据趋势、报告、用药提醒、目标完成状态。
- 成员查看授权数据，不允许编辑用户本人的健康记录。
- 共享发起人可随时撤销成员或调整权限。
- 撤销后新请求立即失效，已生成的临时分享链接同步失效。
- 访问行为记录审计日志。

### 不做范围

- 不做家庭群聊、动态流或社区互动。
- 不允许家庭成员替用户修改医疗信息，除非后续增加“代记录”授权。
- 不把家庭共享默认扩展到 Garmin 或其他设备数据；设备数据需要单独勾选授权。

## 3. 权限模型

### 共享范围

| Scope | 说明 | 默认 |
|---|---|---|
| `dashboard` | 今日健康分、步数、睡眠、饮水、热量摘要 | 开 |
| `trends` | 周/月/年趋势，不含原始明细 | 关 |
| `reports` | 周报/月报和用户主动分享的报告 | 开 |
| `medications` | 用药提醒计划和今日服药状态 | 关 |
| `goals` | 目标类型与完成进度 | 开 |
| `records` | 饮食、运动、饮水、睡眠记录明细 | 关 |
| `devices` | Garmin 或其他设备来源指标 | 关 |

### 成员角色

| Role | 能力 |
|---|---|
| `owner` | 管理家庭、成员、权限和撤销 |
| `member` | 查看自己被授权的数据 |
| `caregiver` | 可查看提醒相关摘要，适合照护场景 |
| `viewer` | 只读报告和仪表盘 |

权限判断必须同时满足：

```text
requestUser 是家庭成员
  AND membership.status = active
  AND permission.scope 包含目标资源
  AND permission.expires_at 未过期
  AND owner 未撤销共享
```

## 4. 核心流程

### 邀请家人

```text
owner 选择邀请
  -> 选择关系、角色、共享范围、有效期
  -> 生成 invitation token
  -> 被邀请人登录或注册
  -> 接受邀请
  -> 创建 family_membership
  -> 写入权限与审计日志
```

### 调整权限

- 只有 `owner` 可以调整。
- 调整后立即删除家庭共享相关缓存。
- 权限变化写入 `family_access_logs`。
- 前端需要展示“最近修改时间”和“授权范围”。

### 撤销共享

- `family_members.status` 改为 `revoked`。
- 相关 `family_share_permissions.revoked_at` 写入当前时间。
- 删除成员可见数据缓存、报告分享缓存和设备共享缓存。
- 成员再次访问返回 `403 FAMILY_SHARE_REVOKED`。

## 5. 数据库设计

所有表必须包含 `created_at`、`updated_at`；撤销、接受、过期等业务时间用独立字段表达。

### `family_groups`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | uuid | 主键 |
| `owner_user_id` | uuid | 家庭所有者 |
| `name` | text | 家庭名称 |
| `status` | text | `active`、`archived` |
| `created_at` / `updated_at` | timestamptz | 审计时间 |

### `family_members`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | uuid | 主键 |
| `family_group_id` | uuid | 家庭空间 |
| `user_id` | uuid | 成员用户 |
| `role` | text | `owner`、`member`、`caregiver`、`viewer` |
| `relationship` | text | 父母、子女、伴侣、其他 |
| `status` | text | `pending`、`active`、`revoked`、`left` |
| `joined_at` | timestamptz | 加入时间 |
| `revoked_at` | timestamptz | 撤销时间 |
| `created_at` / `updated_at` | timestamptz | 审计时间 |

### `family_invitations`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | uuid | 主键 |
| `family_group_id` | uuid | 家庭空间 |
| `inviter_user_id` | uuid | 邀请人 |
| `invitee_phone_hash` | text | 被邀请手机号哈希 |
| `token_hash` | text | 邀请 token 哈希 |
| `role` | text | 预设角色 |
| `scopes` | jsonb | 初始共享范围 |
| `status` | text | `pending`、`accepted`、`expired`、`revoked` |
| `expires_at` | timestamptz | 过期时间 |
| `accepted_at` | timestamptz | 接受时间 |
| `created_at` / `updated_at` | timestamptz | 审计时间 |

### `family_share_permissions`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | uuid | 主键 |
| `family_member_id` | uuid | 成员关系 |
| `owner_user_id` | uuid | 数据所属用户 |
| `scope` | text | 授权范围 |
| `enabled` | boolean | 是否启用 |
| `expires_at` | timestamptz | 授权过期时间 |
| `revoked_at` | timestamptz | 撤销时间 |
| `created_at` / `updated_at` | timestamptz | 审计时间 |

### `family_access_logs`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | uuid | 主键 |
| `viewer_user_id` | uuid | 查看人 |
| `owner_user_id` | uuid | 数据所属用户 |
| `scope` | text | 访问范围 |
| `resource_type` | text | `dashboard`、`report`、`trend` 等 |
| `resource_id` | uuid | 可为空 |
| `action` | text | `view`、`invite`、`update_permission`、`revoke` |
| `created_at` / `updated_at` | timestamptz | 审计时间 |

## 6. API 设计

| 接口 | 说明 |
|---|---|
| `GET /health/family/me` | 当前用户家庭空间、成员和权限摘要 |
| `POST /health/family/invitations` | 创建邀请 |
| `POST /health/family/invitations/:token/accept` | 接受邀请 |
| `PATCH /health/family/members/:memberId/permissions` | 调整成员权限 |
| `DELETE /health/family/members/:memberId` | 撤销成员 |
| `GET /health/family/shared/dashboard/:ownerUserId` | 查看授权仪表盘 |
| `GET /health/family/shared/reports/:ownerUserId` | 查看授权报告 |
| `GET /health/family/access-logs` | 查看家庭访问记录 |

接口实现要求：

- 服务端从 token 解析当前用户，不接受客户端传入 viewer id。
- 共享读取必须走统一 `FamilyPermissionGuard`。
- 所有授权变更需要记录审计日志。
- 家庭共享读取不得返回未授权的原始记录明细。
- 缓存 key 必须包含 `ownerUserId`、`viewerUserId` 和 `scope`。

## 7. UI 原型

### App

已有原型：`UI/app-family-share.svg`。

需要支持状态：

- 无家庭：创建家庭、邀请家人。
- 有成员：成员列表、授权范围、最近查看。
- 待接受邀请：邀请状态与重新发送。
- 权限编辑：按 scope 开关，显示设备数据单独授权。
- 撤销确认：底部确认弹层。

### Web

新增原型：`UI/web-family-share.svg`。

Web 端定位为家庭共享管理台，重点展示成员权限、访问日志和报告分享状态，适合桌面端批量检查。

## 8. 验收标准

- 用户可以邀请、接受、撤销家庭成员。
- 成员只能访问被授权 scope。
- 撤销后成员所有共享接口立即返回无权限。
- 权限调整后首页、报告、设备共享缓存失效。
- 访问日志能展示查看人、资源、时间和动作。
- 家庭共享相关表均具备 `created_at`、`updated_at`。
