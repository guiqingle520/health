# 医生 / 健康顾问视图开发设计方案

## 1. 模块定位

医生 / 健康顾问视图用于在用户授权后，让专业人员查看报告、趋势和用户主动共享的健康摘要，并给出非诊断式备注或生活方式建议。该模块不替代线下诊疗，不提供处方能力。

状态：`Future`，建议在报告与家庭共享权限模型稳定后启动。

## 2. 业务方案

### 使用场景

- 用户向医生分享月度健康报告。
- 健康顾问查看 Pro Plus 用户的趋势摘要，给出计划反馈。
- 家庭照护场景中，顾问只查看用户授权的报告和指标，不访问无关个人信息。

### 角色

| 角色 | 能力 |
|---|---|
| 用户 | 创建授权、选择报告和数据范围、撤销授权 |
| 医生 | 查看授权报告、趋势摘要、添加备注 |
| 健康顾问 | 查看授权报告、建议计划调整 |
| 机构管理员 | 管理医生/顾问账号和服务分配 |

## 3. 授权模型

授权必须由用户主动发起，可设置：

- 授权对象：医生、顾问或机构。
- 授权范围：报告、趋势、目标、用药提醒摘要、设备摘要。
- 授权期限：一次性、7 天、30 天、长期。
- 是否允许备注：默认允许。
- 是否允许导出：默认关闭。

医生/顾问不能反向搜索用户，必须通过授权关系访问。

## 4. 核心流程

```text
用户选择分享给医生/顾问
  -> 选择报告和数据范围
  -> 生成 care authorization
  -> 医生/顾问登录工作台
  -> 查看授权列表
  -> 打开用户报告
  -> 添加备注或建议
  -> 用户在 App/Web 收到反馈
```

撤销授权后：

- 工作台列表不再显示该用户。
- 已打开页面刷新后返回无权限。
- 备注保留但只对用户本人和审计管理员可见。

## 5. 数据库设计

所有表必须包含 `created_at`、`updated_at`。

| 表 | 说明 |
|---|---|
| `care_organizations` | 医疗或健康顾问机构 |
| `care_provider_profiles` | 医生/顾问资料 |
| `care_authorizations` | 用户授权关系 |
| `care_authorization_scopes` | 授权 scope |
| `care_notes` | 医生/顾问备注 |
| `care_access_logs` | 工作台访问日志 |

关键字段：

- `care_authorizations.status`：`active`、`expired`、`revoked`。
- `care_authorizations.expires_at`：授权到期时间。
- `care_notes.visibility`：`user_and_provider`、`provider_only`、`internal_review`。
- `care_access_logs.resource_type`：`report`、`trend`、`profile_summary`。

## 6. API 设计

| 接口 | 说明 |
|---|---|
| `POST /care/authorizations` | 用户创建授权 |
| `GET /care/authorizations/me` | 用户查看授权列表 |
| `DELETE /care/authorizations/:id` | 用户撤销授权 |
| `GET /care/workbench/patients` | 医生/顾问查看授权用户列表 |
| `GET /care/workbench/patients/:userId/reports` | 查看授权报告 |
| `GET /care/workbench/patients/:userId/trends` | 查看授权趋势 |
| `POST /care/workbench/patients/:userId/notes` | 新增备注 |
| `GET /care/notes/me` | 用户查看顾问反馈 |

## 7. 安全与合规

- 医生/顾问账号必须独立角色认证，不复用普通用户权限。
- 工作台接口必须使用 `CareAuthorizationGuard`。
- 所有访问写入 `care_access_logs`。
- 备注文案需要安全提示，不允许输出诊断、处方、急救判断。
- 导出报告需要额外授权。
- 屏幕展示使用脱敏手机号和昵称，不默认展示身份证等高敏信息。

## 8. UI 原型

新增原型：`UI/web-care-provider.svg`。

页面结构：

- 左侧患者授权列表。
- 顶部筛选：待查看、最近反馈、授权即将到期。
- 中间报告与趋势摘要。
- 右侧备注与反馈区。
- 授权范围和到期时间固定展示。

App 侧可复用报告分享页，在“报告与分享”中增加“分享给医生/顾问”和“顾问反馈”入口。

## 9. 验收标准

- 医生/顾问只能看到已授权用户。
- 授权过期或撤销后所有工作台数据不可访问。
- 新增备注后用户侧可见反馈。
- 所有工作台查看行为有审计日志。
- 医生/顾问相关表均具备 `created_at`、`updated_at`。
