# AI 高阶能力开发设计方案

## 1. 模块定位

AI 高阶能力用于提升记录效率和复盘质量，包括拍照识别饮食、自然语言记录、深度报告、建议解释和安全审核。它必须服务于用户理解自己的生活方式，不输出诊断、处方或急救判断。

状态：`Future`，基础 AI 建议、报告 MVP 和目标体系稳定后启动。

## 2. 业务方案

### 能力清单

| 能力 | 用户价值 | 首期形态 |
|---|---|---|
| 拍照识别饮食 | 降低饮食记录成本 | 图片上传后生成候选食物和热量估算 |
| 自然语言记录 | 快速补录 | 用户输入一句话，生成待确认记录草稿 |
| 深度报告 | 长周期复盘 | 周/月趋势解释、目标偏离原因、行动建议 |
| 建议解释 | 提升信任 | 展示建议来源：睡眠、饮水、运动、目标 |
| AI 安全审核 | 降低风险 | 过滤诊断、处方、极端建议 |

## 3. AI 工作流

```text
用户输入图片 / 文本 / 报告请求
  -> 创建 ai_jobs
  -> 收集授权上下文
  -> 安全前置检查
  -> 调用模型或规则引擎
  -> 结构化解析
  -> 安全后置审核
  -> 生成草稿 / 建议 / 报告
  -> 用户确认或反馈
```

所有 AI 生成结果都应该带有：

- `confidence`：置信度。
- `reasons`：引用的指标或记录。
- `disclaimer_key`：安全提示文案 key。
- `review_status`：安全审核状态。

## 4. 拍照识别饮食

流程：

```text
上传图片
  -> 图片安全检查
  -> 食物识别
  -> 份量估算
  -> 营养估算
  -> 返回候选项
  -> 用户确认
  -> 写入 diet_records
```

原则：

- 识别结果默认是草稿，必须由用户确认。
- 热量和营养值展示为估算，不作为精确医疗营养建议。
- 图片原图默认短期保存，生成记录后可按隐私策略清理。

## 5. 自然语言记录

示例输入：

```text
今天中午吃了一碗牛肉面，晚上快走 40 分钟，喝了 1500ml 水
```

输出为待确认草稿：

```json
{
  "dietDrafts": [],
  "exerciseDrafts": [],
  "waterDrafts": [],
  "needsConfirmation": true
}
```

用户确认后才写入正式记录。

## 6. 深度报告与解释

深度报告由报告服务发起 AI 任务，输出结构化 JSON，而不是直接保存整段不可解析文本。

建议结构：

```json
{
  "summary": "本周睡眠稳定，但饮水不足影响运动恢复。",
  "signals": [
    { "type": "sleep", "evidence": "平均 7.1 小时", "impact": "恢复较好" }
  ],
  "actions": [
    { "title": "晚饭后补水 400ml", "difficulty": "low" }
  ],
  "safety": { "medicalDiagnosis": false }
}
```

## 7. 数据库设计

所有表必须包含 `created_at`、`updated_at`。

| 表 | 说明 |
|---|---|
| `ai_jobs` | AI 任务 |
| `ai_inputs` | 输入引用，不直接暴露敏感原文 |
| `ai_outputs` | 结构化输出 |
| `ai_safety_events` | 安全审核记录 |
| `food_recognition_results` | 饮食识别候选 |
| `natural_language_record_drafts` | 自然语言记录草稿 |
| `ai_recommendation_reasons` | 建议解释来源 |
| `ai_feedback_events` | 用户采纳、忽略、纠错反馈 |

## 8. API 设计

| 接口 | 说明 |
|---|---|
| `POST /health/ai/food-photo` | 上传饮食图片并创建识别任务 |
| `GET /health/ai/jobs/:id` | 查询 AI 任务状态 |
| `POST /health/ai/food-photo/:jobId/confirm` | 确认识别结果并写入记录 |
| `POST /health/ai/natural-records/parse` | 解析自然语言记录 |
| `POST /health/ai/natural-records/confirm` | 确认草稿 |
| `POST /health/reports/:id/deep-analysis` | 生成深度报告 |
| `POST /health/ai/recommendations/:id/feedback` | 建议反馈 |

## 9. 安全策略

- AI 输出不得包含诊断结论、处方剂量或急救决策。
- 涉及危险症状时只提示“建议及时就医或联系专业人员”。
- 模型输入只传必要上下文，避免无关敏感信息。
- 生成内容需支持国际化，保存 `locale` 和模板版本。
- 用户纠错反馈不直接训练外部模型，除非有单独授权。

## 10. UI 原型

新增原型：`UI/web-ai-advice.svg`。

页面结构：

- AI 任务列表。
- 拍照识别结果草稿。
- 自然语言解析草稿。
- 建议解释和证据。
- 安全审核状态。

App 侧复用 `UI/app-ai-advice.svg`，后续增加识别草稿确认页。

## 11. 验收标准

- 图片识别和自然语言解析只生成草稿，用户确认后才写记录。
- 每条 AI 建议能展示至少一个来源或解释。
- 安全审核阻断高风险输出。
- 深度报告输出结构化数据。
- AI 相关表均具备 `created_at`、`updated_at`。
