# Companion Context 统一清单

本文档是 `companion context / 陪伴上下文` 的唯一规范来源，用于统一术语、字段、摘要结构与展示口径。其目标是为架构、数据库、API 和 UI 文档提供共享标准，并确保该能力始终服务于用户本人健康管理，而不是演化为独立宠物健康域。

## 1. 定位

Companion context 是用户健康管理系统中的解释层与上下文层。

它用于：

- 解释用户行为变化。
- 补充用户情绪、节律与活动意愿分析。
- 为 AI 建议提供更具体、更生活化的上下文。
- 提高仪表盘与日总结的解释力。

## 2. 非目标

以下内容不属于本能力范围：

- 宠物身体指标记录。
- 宠物疾病、用药、疫苗、就诊与医疗建议。
- 宠物独立健康档案。
- 宠物健康诊断、分诊、护理方案。
- 宠物社交、服务、电商或领养平台能力。

## 3. 标准术语

| 层级 | 标准名称 | 用途 |
|---|---|---|
| 总概念 | `companion context` / `陪伴上下文` | 文档、架构、产品语义 |
| 原始对象 | `companionContext` | API / DTO / 逻辑输入对象 |
| 摘要对象 | `companionContextSummary` | 日总结 / 仪表盘聚合对象 |
| UI 标签 | `陪伴上下文` | 正式展示名称 |
| UI 短标签 | `陪伴摘要` | 轻量卡片或摘要标题 |

## 4. 原始字段

| 逻辑含义 | 数据库字段 | API 字段 | 类型 | 必填 |
|---|---|---|---|---|
| 宠物名称 | `pet_name` | `petName` | string | 否 |
| 宠物类型 | `pet_type` | `petType` | string | 否 |
| 互动类型 | `interaction_type` | `interactionType` | string | 是 |
| 互动时间 | `interaction_time` | `interactionTime` | datetime string | 是 |
| 互动时长 | `duration_minutes` | `durationMinutes` | integer | 否 |
| 互动前情绪 | `mood_before` | `moodBefore` | integer | 否 |
| 互动后情绪 | `mood_after` | `moodAfter` | integer | 否 |
| 精力水平 | `energy_level` | `energyLevel` | integer | 否 |
| 互动意愿 | `willingness` | `willingness` | integer | 否 |
| 备注 | `note` | `note` | string | 否 |

## 5. companionContext 示例

```json
{
  "petName": "Milo",
  "petType": "dog",
  "interactionType": "companion",
  "interactionTime": "2026-05-16T21:00:00+08:00",
  "durationMinutes": 20,
  "moodBefore": 2,
  "moodAfter": 4,
  "energyLevel": 2,
  "willingness": 3,
  "note": "晚间安静陪伴"
}
```

## 6. companionContextSummary 示例

```json
{
  "interactionCount": 2,
  "totalDurationMinutes": 35,
  "moodDeltaAvg": 1.5,
  "routineSupport": "晚间陪伴帮助情绪回稳",
  "activitySupport": "短时互动帮助维持生活规律",
  "qualityImpactSignal": "睡眠不足可能降低主动互动质量"
}
```

## 7. 展示规则

- 始终以用户本人为分析主语。
- 只作为健康主流程中的轻量解释层。
- 不形成独立宠物首页或宠物健康中心。
- 不输出任何宠物健康判断。
- 推荐展示在仪表盘摘要、日总结说明和 AI 洞察中。
