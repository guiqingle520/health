# 健康档案子功能开发设计方案

## 1. 模块范围

本方案补齐“我的 - 健康档案”下的三个子功能：

- 健康档案：完整度、基础信息、慢病史、过敏史、运动习惯、设备数据来源摘要。
- 用药管理：药品列表、服药计划、提醒开关、服药记录、停用归档。
- 体检报告：报告列表、报告详情、关键指标、异常标记、报告上传 / 手动录入。

状态标签：

- `Current`：当前已有基础档案、建档和“我的”入口。
- `Next`：近期可开发范围，本文写到 UI、接口、数据、缓存和验收。
- `Future`：OCR 识别、医生解读、处方联动、机构报告直连等远期方向。

## 2. 用户入口

| 功能 | App 入口 | Web 入口 | 原型 |
|---|---|---|---|
| 健康档案 | 我的 -> 健康档案 -> 健康档案 | 健康档案 -> 总览 | `UI/app-health-profile.svg` / `UI/web-health-profile.svg` |
| 用药管理 | 我的 -> 健康档案 -> 用药管理 | 健康档案 -> 用药管理 | `UI/app-medication-management.svg` / `UI/web-medication-management.svg` |
| 体检报告 | 我的 -> 健康档案 -> 体检报告 | 健康档案 -> 体检报告 | `UI/app-exam-report.svg` / `UI/web-exam-report.svg` |

## 3. 功能设计

### 健康档案

Next 功能：

- 展示档案完整度和缺失项。
- 展示基础信息摘要：年龄、性别、身高、体重、健康目标。
- 展示健康背景：慢病史、过敏史、家族史、运动习惯。
- 展示数据来源：手动记录、Garmin、体检报告。
- 提供编辑入口：基础信息、健康背景、运动习惯。

不做：

- 不做诊断结论。
- 不把体检指标直接转化为疾病判断。
- 不在未授权家庭共享中展示敏感档案。

### 用药管理

Next 功能：

- 新增、编辑、停用药品。
- 设置服药频次、剂量、提醒时间、开始日期、结束日期。
- 展示今日待服、已服、漏服状态。
- 支持“已服用”“稍后提醒”“跳过一次”。
- 支持停用归档，停用后不再提醒，但保留历史记录。

边界：

- 系统只做记录和提醒，不给出处方、剂量建议或替换药建议。
- 药品名称、剂量来自用户输入，首期不接药品知识库。
- 与 AI 建议联动时只能提示“按计划记录 / 咨询医生”，不能输出医疗处置。

### 体检报告

Next 功能：

- 报告列表：体检日期、机构、状态、异常项数量。
- 报告详情：关键指标、参考范围、趋势方向、来源文件。
- 支持手动录入报告摘要。
- 支持上传文件入口，首期可只保存文件信息和手动结构化结果。
- 异常项只按报告原始参考范围展示，不做诊断。

Future：

- OCR / PDF 结构化识别。
- 医生 / 健康顾问批注。
- 与报告中心、AI 周报、家庭共享授权联动。

## 4. UI 页面设计

### App 健康档案页

页面结构：

```text
AppHealthProfilePage
  TopBar
  CompletionCard
  BasicInfoSummaryCard
  HealthBackgroundCard
  DataSourceCard
  ActionList
```

关键状态：

- 完整度不足时展示缺失项和补充按钮。
- 无慢病 / 无过敏时展示“未填写”，不展示“正常”。
- Garmin 未连接时，数据来源卡展示“未接入设备”。

### App 用药管理页

页面结构：

```text
AppMedicationManagementPage
  TopBar
  TodayMedicationSummary
  MedicationScheduleList
  ArchivedMedicationEntry
  AddMedicationButton
```

交互：

- 今日药品卡支持“已服用”“稍后提醒”“跳过”。
- 点击药品进入编辑页，首期原型展示列表和主操作。
- 停用药品需二次确认。

### App 体检报告页

页面结构：

```text
AppExamReportPage
  TopBar
  LatestReportCard
  KeyIndicatorList
  ReportHistoryList
  UploadReportButton
```

交互：

- 点击指标进入指标趋势页 Future。
- 上传报告首期进入手动录入或文件选择入口。
- 异常项以文字标签和柔和橙色提示，不只依赖颜色。

### Web 页面

Web 使用同一侧边导航和健康档案子导航：

- 健康档案总览：左侧子导航，中间档案内容，右侧完整度 / 数据来源。
- 用药管理：表格 + 今日提醒侧栏 + 新增按钮。
- 体检报告：报告列表 + 指标详情 + 上传入口。

## 5. 前端开发设计

### 路由

```text
App:
/profile/health-profile
/profile/medications
/profile/exam-reports

Web:
/health-profile
/health-profile/medications
/health-profile/exam-reports
```

### 组件

| 组件 | 说明 |
|---|---|
| `HealthProfileCompletionCard` | 档案完整度和缺失项 |
| `HealthProfileSummaryCard` | 基础信息和健康背景摘要 |
| `MedicationTodayCard` | 今日服药任务 |
| `MedicationScheduleCard` | 药品计划卡 |
| `ExamReportSummaryCard` | 最新体检报告摘要 |
| `ExamIndicatorRow` | 单个体检指标行 |
| `ProfileSubnav` | Web 健康档案子导航 |

### 状态

| 状态 | 说明 |
|---|---|
| `loading` | 页面首次加载 |
| `ready` | 数据加载成功 |
| `empty` | 无药品 / 无体检报告 |
| `partial` | 部分模块未填写 |
| `saving` | 新增、编辑、状态更新中 |
| `error` | 接口失败 |
| `offline` | 有本地缓存但不可提交 |

## 6. API 设计

所有接口默认使用 `JwtAuthGuard`，服务端只使用 token `sub` 作为 `userId`。

### 健康档案

`GET /health/profile-detail/me`

```json
{
  "completionRate": 86,
  "missingFields": ["allergies"],
  "basicInfo": {
    "nickname": "张先生",
    "age": 31,
    "gender": "male",
    "heightCm": 175,
    "weightKg": 71.6,
    "goal": "fat_loss"
  },
  "healthBackground": {
    "chronicDiseases": ["hypertension"],
    "allergies": [],
    "familyHistory": ["diabetes"],
    "exerciseHabit": "每周 3 次快走"
  },
  "dataSources": [
    { "type": "manual", "status": "active", "lastUpdatedAt": "2026-05-19T09:00:00+08:00" },
    { "type": "garmin", "status": "connected", "lastUpdatedAt": "2026-05-18T22:00:00+08:00" }
  ]
}
```

`PATCH /health/profile-detail/me`

```json
{
  "chronicDiseases": ["hypertension"],
  "allergies": ["penicillin"],
  "familyHistory": ["diabetes"],
  "exerciseHabit": "每周 3 次快走"
}
```

### 用药管理

`GET /health/medications`

```json
{
  "today": {
    "pending": 1,
    "taken": 2,
    "missed": 0
  },
  "items": [
    {
      "id": "medication-uuid",
      "name": "二甲双胍",
      "dosage": "0.5g",
      "frequency": "daily",
      "times": ["08:00", "20:00"],
      "status": "active",
      "todayStatus": "pending",
      "startDate": "2026-05-01",
      "endDate": null
    }
  ]
}
```

`POST /health/medications`

```json
{
  "name": "二甲双胍",
  "dosage": "0.5g",
  "frequency": "daily",
  "times": ["08:00", "20:00"],
  "startDate": "2026-05-01",
  "endDate": null,
  "reminderEnabled": true
}
```

`PATCH /health/medications/:id`

更新药品名称、剂量、频次、提醒时间或状态。

`POST /health/medications/:id/actions`

```json
{
  "action": "taken",
  "scheduledAt": "2026-05-19T08:00:00+08:00"
}
```

动作枚举：`taken`、`snooze`、`skip`、`archive`。

### 体检报告

`GET /health/exam-reports?from&to&limit`

```json
{
  "items": [
    {
      "id": "exam-report-uuid",
      "title": "年度体检报告",
      "examDate": "2026-05-10",
      "organization": "市中心体检中心",
      "status": "ready",
      "abnormalCount": 2,
      "keyIndicators": [
        {
          "name": "空腹血糖",
          "value": 6.1,
          "unit": "mmol/L",
          "referenceRange": "3.9-6.1",
          "flag": "borderline"
        }
      ]
    }
  ]
}
```

`POST /health/exam-reports`

```json
{
  "title": "年度体检报告",
  "examDate": "2026-05-10",
  "organization": "市中心体检中心",
  "source": "manual",
  "items": [
    {
      "name": "空腹血糖",
      "value": 6.1,
      "unit": "mmol/L",
      "referenceRange": "3.9-6.1",
      "flag": "borderline"
    }
  ]
}
```

`GET /health/exam-reports/:id`

返回报告详情和全部结构化指标。

### 报告与分享

`GET /health/reports?period=week|month|quarter`

返回报告摘要、生成时间、关键变化和分享状态。

`POST /health/reports/:id/export`

导出 PDF 或可分享摘要。

`POST /health/reports/:id/share`

创建分享链接或指定分享对象。

`DELETE /health/reports/:id/share/:shareId`

撤销分享。

### 通知提醒和目标设定

`GET /health/notifications/settings`

读取饮水、运动、睡眠、周报和目标提醒设置。

`PUT /health/notifications/settings`

保存提醒设置和静默时段。

`GET /health/goals/me`

读取当前用户目标列表。

`PUT /health/goals/me`

批量保存目标设定。

## 7. 数据库设计

### `health_profile_details`

| 字段 | 说明 |
|---|---|
| `user_id` | 用户 ID |
| `chronic_diseases` | 慢病史，JSONB |
| `allergies` | 过敏史，JSONB |
| `family_history` | 家族史，JSONB |
| `exercise_habit` | 运动习惯 |
| `updated_at` | 更新时间 |

### `medications`

| 字段 | 说明 |
|---|---|
| `id` | 药品 ID |
| `user_id` | 用户 ID |
| `name` | 药品名称 |
| `dosage` | 剂量文本 |
| `frequency` | 频次 |
| `times` | 提醒时间 JSONB |
| `start_date` | 开始日期 |
| `end_date` | 结束日期 |
| `reminder_enabled` | 是否提醒 |
| `status` | `active` / `archived` |
| `created_at` | 创建时间 |
| `updated_at` | 更新时间 |

### `medication_action_logs`

| 字段 | 说明 |
|---|---|
| `id` | 日志 ID |
| `user_id` | 用户 ID |
| `medication_id` | 药品 ID |
| `action` | `taken` / `snooze` / `skip` |
| `scheduled_at` | 计划时间 |
| `acted_at` | 操作时间 |

### `exam_reports`

| 字段 | 说明 |
|---|---|
| `id` | 报告 ID |
| `user_id` | 用户 ID |
| `title` | 报告标题 |
| `exam_date` | 体检日期 |
| `organization` | 机构 |
| `source` | `manual` / `upload` / `ocr` |
| `file_url` | 文件地址 |
| `status` | `draft` / `ready` / `failed` |
| `abnormal_count` | 异常项数量 |
| `created_at` | 创建时间 |

### `exam_report_items`

| 字段 | 说明 |
|---|---|
| `id` | 指标 ID |
| `exam_report_id` | 报告 ID |
| `user_id` | 用户 ID |
| `name` | 指标名称 |
| `value` | 指标值 |
| `unit` | 单位 |
| `reference_range` | 参考范围 |
| `flag` | `normal` / `high` / `low` / `borderline` |

### `notification_settings`

| 字段 | 说明 |
|---|---|
| `user_id` | 用户 ID |
| `water_enabled` | 饮水提醒 |
| `exercise_enabled` | 运动提醒 |
| `sleep_enabled` | 睡眠提醒 |
| `weekly_report_enabled` | 周报提醒 |
| `goal_reminder_enabled` | 目标提醒 |
| `quiet_hours_enabled` | 静默时段开关 |
| `quiet_hours_start` | 静默开始 |
| `quiet_hours_end` | 静默结束 |
| `created_at` | 创建时间 |
| `updated_at` | 更新时间 |

### `health_goals`

| 字段 | 说明 |
|---|---|
| `id` | 目标 ID |
| `user_id` | 用户 ID |
| `goal_type` | water / exercise_minutes / sleep_hours / steps / calories / weight |
| `target_value` | 目标值 |
| `unit` | 单位 |
| `period` | daily / weekly / monthly |
| `start_date` | 开始日期 |
| `end_date` | 结束日期 |
| `reminder_enabled` | 是否提醒 |
| `status` | active / paused / completed / archived |
| `source` | manual / system |
| `created_at` | 创建时间 |
| `updated_at` | 更新时间 |

## 8. 缓存设计

| Key | TTL | 失效触发 |
|---|---|---|
| `health:profile-detail:{userId}` | 10 分钟 | 健康背景、基础信息、设备来源变化 |
| `health:profile-center:{userId}` | 5 分钟 | 健康档案、用药、体检报告变化 |
| `health:medications:{userId}:{date}` | 5 分钟 | 药品新增、编辑、停用、服药动作 |
| `health:exam-reports:{userId}:{from}:{to}:{limit}` | 10 分钟 | 报告新增、编辑、删除、解析完成 |
| `health:reports:{userId}:{period}:{start}:{end}` | 30 分钟 | 报告生成、导出、分享状态变化 |
| `health:goals:{userId}` | 10 分钟 | 目标新增、编辑、删除、达成状态变化 |
| `health:dashboard:{userId}:{date}` | 1-2 分钟 | 用药提醒、体检关键指标进入首页时 |

Redis 不保存报告文件本体、药品图片、处方图片或任何 token。

## 9. 安全与合规

- 所有接口必须鉴权。
- 药品和体检报告属于敏感健康数据，家庭共享前必须有明确授权。
- 用药管理只做提醒和记录，不输出处方建议。
- 体检报告只展示原始参考范围和用户录入结果，不做诊断。
- 报告分享必须支持撤销和权限最小化。
- 上传文件需要限制类型和大小，Future 接入病毒扫描。
- 日志不得输出完整报告内容、药品明细或上传文件地址签名。

## 10. 验收标准

### 健康档案

- 可查看档案完整度、缺失项、基础信息和健康背景。
- 未填写慢病史、过敏史时显示“未填写”，不误导为“无异常”。
- 编辑健康背景后，“我的”页档案完整度刷新。

### 用药管理

- 可新增药品和提醒时间。
- 今日药品可标记已服用、稍后提醒、跳过。
- 停用药品后不再进入今日提醒。
- 保存失败时保留表单输入。
- AI 建议中引用用药信息时不得输出剂量建议。

### 体检报告

- 可查看报告列表、最新报告和关键指标。
- 可手动新增体检报告和指标。
- 异常项必须显示文字标签。
- 删除或更新报告后缓存失效。
- 没有报告时显示空态和添加入口。

### 报告与分享

- 可生成周期报告摘要。
- 可导出并分享。
- 分享状态可撤销且可追踪。

### 通知提醒和目标设定

- 可读取并修改提醒设置。
- 可读取并修改目标设定。
- 保存后首页、趋势、AI 建议和报告同步更新。

### 原型

- App 原型：`UI/app-health-profile.svg`、`UI/app-medication-management.svg`、`UI/app-exam-report.svg`。
- Web 原型：`UI/web-health-profile.svg`、`UI/web-medication-management.svg`、`UI/web-exam-report.svg`。
- `UI/index.html` 和 `UI/ui-prototype-board.svg` 能直接查看这些原型。

## 11. 开发任务拆分

### 前端

1. 新增健康档案、用药管理、体检报告三条路由。
2. 实现健康档案总览卡片、完整度卡片、缺失项提示。
3. 实现用药列表、今日提醒、动作按钮和停用确认。
4. 实现体检报告列表、关键指标、空态和新增入口。
5. 实现报告与分享页、通知提醒和目标设定页。
6. 接入加载态、空态、错误态、离线态。

### 后端

1. 新增 `profile-detail` 聚合接口。
2. 新增用药管理 CRUD 和动作日志接口。
3. 新增体检报告列表、详情和新增接口。
4. 新增报告分享、通知提醒和目标设定接口。
5. 新增数据表和索引。
6. 接入 Redis 缓存和写入后失效。
7. 增加 e2e：鉴权、跨用户隔离、字段校验、缓存失效。

### 测试

1. 健康档案完整度和缺失项计算。
2. 用药提醒状态流转。
3. 体检报告异常项展示。
4. Redis 不可用降级。
5. 家庭共享未授权不可见。
