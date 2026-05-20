# 基本信息开发设计方案

## 1. 模块定位

基本信息是健康档案的核心子模块，覆盖昵称、性别、年龄、身高、体重和健康目标。该模块同时服务首次建档和“我的 - 健康档案 - 基本信息”编辑场景。

首期目标：

- 让用户能查看和修改基础健康信息。
- 为首页健康分、趋势、AI 建议、报告和设备数据解释提供基础上下文。
- 保持首次建档和后续编辑使用同一套字段、校验规则和接口语义。

状态标签：

- `Current`：已有建档接口和建档 UI 原型。
- `Next`：补齐从“我的”进入的基本信息编辑页、接口校验、缓存失效和验收标准。
- `Future`：扩展慢病史、过敏史、用药情况、运动习惯等健康档案详情。

## 2. 用户场景

### Next

| 场景 | 入口 | 目标 | 结果 |
|---|---|---|---|
| 首次建档 | 登录后未建档 | 填写基础资料 | 保存后进入首页 |
| 修改基础资料 | 我的 -> 健康档案 -> 基本信息 | 更新昵称、身高、体重、目标等 | 返回“我的”并刷新资料卡 |
| 目标调整 | 我的 -> 资料卡 / 基本信息 | 从控糖、减脂、增肌等目标中切换 | 后续建议和报告按新目标解释 |
| 体重更新 | 我的 -> 基本信息 | 修改当前体重 | 首页、趋势、报告刷新 |
| 校验失败 | 保存时字段非法 | 给出字段级错误 | 不提交接口 |
| 网络失败 | 保存接口失败 | 保留用户输入 | 展示重试提示 |

## 3. 字段设计

### 字段清单

| 字段 | API 字段 | 类型 | 必填 | 校验 | UI 控件 |
|---|---|---|---|---|---|
| 昵称 | `nickname` | string | 是 | 1-20 字 | 文本输入 |
| 性别 | `gender` | enum | 是 | `male` / `female` / `unknown` | 分段选择 |
| 年龄 | `age` | number | 是 | 1-120 | 数字输入 / stepper |
| 身高 | `heightCm` | number | 是 | 50-250 | 数字输入，单位 cm |
| 体重 | `weightKg` | number | 是 | 20-300 | 数字输入，单位 kg |
| 健康目标 | `goal` | enum | 是 | 见下表 | 单选 chip |

### 健康目标枚举

| 值 | 展示文案 | 使用场景 |
|---|---|---|
| `fat_loss` | 减脂 | 热量、运动和体重趋势建议 |
| `muscle_gain` | 增肌 | 蛋白质、力量训练建议 |
| `maintain` | 保持健康 | 均衡饮食和活动建议 |
| `glucose_control` | 控糖 | 饮食结构、餐后活动建议 |
| `improve_sleep` | 改善睡眠 | 睡眠、压力和作息建议 |
| `improve_fitness` | 提升体能 | 运动频率和恢复建议 |

兼容要求：当前旧值 `maintain` 继续有效。若已有代码使用 `fat_loss`、`muscle_gain`、`maintain` 三类目标，新增枚举应在后端 DTO、数据库约束和前端映射中同步处理。

## 4. UI 原型

### App 原型

文件：`UI/app-basic-profile-edit.svg`

页面路径：

```text
我的 -> 健康档案 -> 基本信息
```

页面结构：

```text
AppBasicProfileEditPage
  TopBar(back, title, saveState)
  ProfileCompletionCard
  BasicInfoFormCard
    nickname
    gender segmented control
    age / height / weight numeric fields
    goal chips
  DataUsageTipCard
  StickySaveBar
```

交互：

- 返回：若表单未修改，直接返回；若已修改，弹出“放弃修改”确认。
- 保存：字段合法时调用 `PATCH /health/profiles/me`。
- 保存成功：toast 提示“已更新基本信息”，返回“我的”并刷新 `GET /health/profile-center/me`。
- 保存失败：保留输入，底部按钮恢复可点击，展示页面内错误。
- 年龄、身高、体重只允许数字输入。
- 健康目标单选，当前选中项使用青绿色高亮。

### Web 原型

文件：`UI/web-basic-profile-edit.svg`

页面路径：

```text
Web 工作台 -> 健康档案 -> 基本信息
```

页面结构：

```text
WebBasicProfileEditPage
  Sidebar
  Header
  ProfileSubnav
  BasicInfoFormPanel
  HealthContextPreviewPanel
  SaveActionBar
```

交互：

- 桌面端表单按两列布局。
- 右侧展示档案完整度、BMI 预览、字段用途说明。
- 保存成功后保留当前页并显示成功提示。
- 取消返回健康档案详情页。

## 5. 前端开发设计

### 路由

```text
App: /profile/basic-info
Web: /health-profile/basic-info
```

Flutter 可先用 Navigator 页面枚举实现，后续路由库保持路径语义。

### 页面状态

| 状态 | 触发 | UI 表现 |
|---|---|---|
| `loading` | 进入页面读取档案 | 表单骨架屏 |
| `ready` | 档案读取成功 | 展示表单 |
| `dirty` | 任一字段被修改 | 保存按钮变为可用 |
| `validating` | 点击保存后本地校验 | 字段级错误 |
| `saving` | 接口提交中 | 保存按钮 loading，禁用重复提交 |
| `success` | 保存成功 | toast / 顶部成功提示 |
| `error` | 读取或保存失败 | 页面内错误 + 重试 |
| `offline` | 网络不可用 | 允许查看本地缓存，禁止保存或提示稍后重试 |

### 前端模型

```dart
class BasicProfileFormState {
  String nickname;
  Gender gender;
  int age;
  double heightCm;
  double weightKg;
  HealthGoal goal;
  bool dirty;
  bool saving;
  Map<String, String> fieldErrors;
}

enum Gender { male, female, unknown }

enum HealthGoal {
  fatLoss,
  muscleGain,
  maintain,
  glucoseControl,
  improveSleep,
  improveFitness,
}
```

### 本地校验

- 昵称去除首尾空格后不能为空。
- 昵称超过 20 字时禁止提交。
- 年龄、身高、体重为空或非数字时禁止提交。
- 年龄、身高、体重超出范围时展示字段级错误。
- 健康目标必须有选中值。
- 保存按钮只有在 `dirty && valid && !saving` 时可点击。

### 脏数据处理

- 表单初始化时保存 `initialValue`。
- 每次字段变更后与 `initialValue` 对比计算 `dirty`。
- 返回时若 `dirty=true`，弹出确认：
  - 放弃修改：返回上一页。
  - 继续编辑：关闭弹窗。

## 6. 后端 API 设计

### `GET /health/profiles/me`

Current 已存在，用于进入编辑页时拉取当前档案。

响应方向：

```json
{
  "nickname": "张先生",
  "age": 30,
  "gender": "male",
  "heightCm": 175,
  "weightKg": 72,
  "goal": "maintain"
}
```

### `PATCH /health/profiles/me`

Next 推荐使用 PATCH 语义编辑当前用户档案。若当前代码只支持 `POST /health/profiles/me` upsert，可先复用 POST，文档和前端服务层保留 PATCH 方向。

请求：

```json
{
  "nickname": "张先生",
  "age": 31,
  "gender": "male",
  "heightCm": 175,
  "weightKg": 71.6,
  "goal": "fat_loss"
}
```

响应：

```json
{
  "nickname": "张先生",
  "age": 31,
  "gender": "male",
  "heightCm": 175,
  "weightKg": 71.6,
  "goal": "fat_loss",
  "updatedAt": "2026-05-19T10:30:00+08:00"
}
```

错误：

| 状态码 | 错误码 | 说明 |
|---|---|---|
| 401 | `AUTH_REQUIRED` | 未登录 |
| 400 | `VALIDATION_FAILED` | 字段校验失败 |
| 404 | `PROFILE_NOT_FOUND` | 编辑时档案不存在 |
| 409 | `PROFILE_VERSION_CONFLICT` | Future：多端编辑冲突 |

### DTO 校验

```ts
class UpdateMyProfileDto {
  nickname: string;
  age: number;
  gender: 'male' | 'female' | 'unknown';
  heightCm: number;
  weightKg: number;
  goal:
    | 'fat_loss'
    | 'muscle_gain'
    | 'maintain'
    | 'glucose_control'
    | 'improve_sleep'
    | 'improve_fitness';
}
```

## 7. 数据库设计

### Current

复用 `user_profiles`：

- `user_id`
- `nickname`
- `age`
- `gender`
- `height_cm`
- `weight_kg`
- `goal`
- `updated_at`

### Next

- 保持基础信息在 `user_profiles` 中，不拆新表。
- 若 `goal` 增加新枚举，应确认数据库约束或应用层校验同步更新。
- 建议增加 `created_at`，便于计算档案创建时间和建档完成率。
- Future 如需记录体重长期变化，不应仅覆盖 `user_profiles.weight_kg`，应同步写入 `health_metric_events(metric_type='weight')`。

## 8. 缓存与刷新

### Redis Key

| Key | TTL | 说明 |
|---|---|---|
| `health:profile:{userId}` | 10 分钟 | 当前用户基础档案 |
| `health:profile-center:{userId}` | 5 分钟 | 我的页聚合资料 |
| `health:dashboard:{userId}:{date}` | 1-2 分钟 | 今日首页 |
| `health:trends:{userId}:weight:*` | 10 分钟 | 体重趋势，若体重同步写事件则失效 |

### 失效规则

基本信息保存成功后：

- 删除 `health:profile:{userId}`。
- 删除 `health:profile-center:{userId}`。
- 删除当日 `health:dashboard:{userId}:{date}`。
- 若体重变化并写入指标事件，删除体重趋势和报告缓存。

Redis 删除失败不回滚数据库更新，但必须记录 warning。

## 9. 与其他模块关系

| 模块 | 影响 |
|---|---|
| 首页仪表盘 | 昵称、目标、体重变化会影响健康分解释和卡片文案 |
| 数据趋势 | 体重更新可进入体重趋势 |
| AI 建议 | 目标、年龄、身高、体重影响建议规则 |
| 报告 | 报告摘要需要展示周期内目标和基础资料 |
| Garmin | Garmin 体重 / 体成分 Future 可与手动体重合并 |
| 我的页 | 保存后刷新资料卡、完整度和目标展示 |

## 10. 安全与隐私

- 接口必须鉴权，只能编辑当前用户。
- 不允许客户端传 `userId`。
- 日志不记录完整手机号，不记录请求体中的敏感健康详情。
- 基本信息属于个人健康数据，家庭共享场景必须按授权范围过滤。
- Web 端保存操作需防止 CSRF，依赖 Bearer Token 时仍需检查 CORS 和来源配置。

## 11. 验收标准

### 功能验收

- 从“我的 - 健康档案 - 基本信息”可进入编辑页。
- 编辑页能正确回显当前档案。
- 修改昵称、年龄、性别、身高、体重、目标后可保存。
- 保存成功后返回“我的”或停留 Web 当前页，并刷新展示数据。
- 未修改时保存按钮禁用。
- 已修改返回时有放弃修改确认。

### 校验验收

- 昵称为空或超过 20 字不能提交。
- 年龄小于 1 或大于 120 不能提交。
- 身高小于 50 或大于 250 不能提交。
- 体重小于 20 或大于 300 不能提交。
- 未选择目标不能提交。
- 服务端返回 `VALIDATION_FAILED` 时能映射到字段错误或顶部错误。

### 缓存验收

- 保存成功后 `profile-center` 再次读取能看到新昵称 / 新目标。
- 保存成功后首页重新读取不展示旧目标文案。
- Redis 不可用时仍能读取和保存基础信息。

### UI 验收

- App 原型 `UI/app-basic-profile-edit.svg` 可在 `UI/index.html` 打开。
- Web 原型 `UI/web-basic-profile-edit.svg` 可在 `UI/index.html` 打开。
- 字段、按钮、提示文案在移动端 430px 宽度内不重叠。
- Web 端 1440px 宽度下表单、预览、操作区不重叠。

## 12. 开发任务拆分

### 前端

1. 新增基本信息编辑页路由。
2. 封装基础表单组件：文本输入、数字输入、分段选择、目标 chip。
3. 接入 `GET /health/profiles/me` 回显数据。
4. 接入 `PATCH /health/profiles/me` 或兼容当前 `POST /health/profiles/me`。
5. 实现本地校验和字段错误展示。
6. 实现 dirty 检测和返回确认。
7. 保存成功后刷新 `profile-center`。
8. 增加无网络、保存失败、token 失效处理。

### 后端

1. 增加或确认 `PATCH /health/profiles/me`。
2. 完善 DTO 校验。
3. 服务端只使用 JWT `sub` 作为 `userId`。
4. 更新 `user_profiles`。
5. 若体重变化，同步写入 `health_metric_events` 的实现作为 Next+ 任务。
6. 保存成功后失效 Redis 缓存。
7. 增加 e2e：成功、字段非法、未登录、未建档、缓存失效。

### 测试

1. App 表单字段校验。
2. Web 表单字段校验。
3. API DTO 校验。
4. 保存成功后“我的”资料刷新。
5. 保存失败保留输入。
6. Redis 不可用降级。
7. 不同用户不能编辑彼此档案。
