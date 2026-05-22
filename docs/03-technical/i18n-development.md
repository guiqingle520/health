# 国际化开发设计方案

## 1. 目标

HealthGuard 首期需要支持 5 种界面语言：

| 语言 | Canonical Locale | 兼容别名 |
|---|---|---|
| 中文简体 | `zh-Hans` | `zh-CN`、`zh-SG` |
| 中文繁体 | `zh-Hant` | `zh-TW`、`zh-HK`、`zh-MO` |
| 英文 | `en` | `en-US`、`en-GB` |
| 日文 | `ja` | `ja-JP` |
| 韩文 | `ko` | `ko-KR` |

设计要求：

- 项目级规则：后续所有新增功能、页面、弹窗、表单、错误提示、通知、报告、AI 建议入口文案都必须支持多语言。
- 默认语言：`zh-Hans`。
- 支持跟随系统语言，也支持用户手动选择。
- 后续新增语言时，不改业务代码，只新增 locale 配置和翻译资源。
- 前端 UI 文案、错误提示、单位显示、日期格式、报告和 AI 建议入口文案都必须走国际化层。
- 后端返回稳定错误码，客户端负责翻译用户可见错误；后端生成类内容按请求 locale 生成或返回可翻译结构。

## 2. 设计原则

- Canonical locale 使用 BCP 47 风格：`zh-Hans`、`zh-Hant`、`en`、`ja`、`ko`。
- 用户偏好存储 canonical locale，不直接存系统传入的别名。
- 翻译 key 稳定，不把中文原文当 key。
- 业务枚举只传稳定值，例如 `fat_loss`、`male`、`taken`，展示文案由前端翻译。
- 错误响应只依赖 `errorCode` 和字段名，不依赖后端中文错误文本。
- 数字、日期、时间、单位跟随 locale 和用户单位偏好格式化。
- AI 建议、健康报告等生成内容必须记录生成时 locale，避免用户切换语言后混用旧语言内容。

## 3. Locale 决策流程

```text
用户手动选择 locale
  -> user_preferences.locale
  -> App 本地持久化 locale
  -> API 请求头 Accept-Language / X-Locale
  -> 后端内容生成使用该 locale

未手动选择
  -> 跟随系统语言
  -> locale alias normalize
  -> 不支持则回退 zh-Hans
```

优先级：

1. 用户手动选择。
2. 系统语言。
3. 默认 `zh-Hans`。

回退链：

| 输入 | 回退 |
|---|---|
| `zh-CN`、`zh-SG` | `zh-Hans` |
| `zh-TW`、`zh-HK`、`zh-MO` | `zh-Hant` |
| `en-US`、`en-GB` | `en` |
| `ja-JP` | `ja` |
| `ko-KR` | `ko` |
| 未支持语言 | `zh-Hans` |

## 4. Flutter 前端方案

### 推荐依赖

Next 阶段建议引入：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true
```

`l10n.yaml`：

```yaml
arb-dir: lib/l10n
template-arb-file: app_zh_Hans.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
```

推荐目录：

```text
apps/mobile/lib/l10n/
  app_zh_Hans.arb
  app_zh_Hant.arb
  app_en.arb
  app_ja.arb
  app_ko.arb
```

### App 初始化

`MaterialApp` 需要接入：

```dart
MaterialApp(
  locale: currentLocale,
  supportedLocales: const [
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
)
```

### 文案 key 规范

| 类型 | 命名 |
|---|---|
| 页面标题 | `profile.title`、`dashboard.title` |
| 按钮 | `common.save`、`common.cancel` |
| 表单字段 | `profile.basic.nickname.label` |
| 字段错误 | `validation.age.range` |
| 业务枚举 | `goal.fatLoss`、`gender.male` |
| 空态 | `empty.examReports.title` |
| 错误码 | `error.AUTH_REQUIRED` |

ARB key 不建议带点号时，可使用下划线风格：

```json
{
  "common_save": "保存",
  "profile_basic_title": "基本信息",
  "goal_fat_loss": "减脂",
  "error_AUTH_REQUIRED": "请先登录"
}
```

### 前端状态

```dart
class LocaleState {
  LocaleMode mode; // system / manual
  String locale; // zh-Hans / zh-Hant / en / ja / ko
}
```

切换语言后：

- 立即刷新当前页面文案。
- 持久化本地偏好。
- 调用 `PUT /health/preferences/me` 保存后端偏好。
- 后续 API 请求带 `Accept-Language` 和 `X-Locale`。
- 已缓存的本地页面数据保留，展示层重新格式化。

## 5. Web 前端方案

Web 工作台同样使用 canonical locale：

- UI 框架未定时，文档先约定资源结构，不绑定具体库。
- 推荐资源目录：`apps/web/src/locales/{locale}.json`。
- 所有页面从 `t(key, params)` 获取文案。
- 日期、数字、单位通过 `Intl.DateTimeFormat`、`Intl.NumberFormat` 或框架等价工具格式化。

推荐资源文件：

```text
apps/web/src/locales/
  zh-Hans.json
  zh-Hant.json
  en.json
  ja.json
  ko.json
```

## 6. 后端 API 方案

### 请求头

客户端所有鉴权请求附带：

```text
Accept-Language: zh-Hans
X-Locale: zh-Hans
```

规则：

- `X-Locale` 优先于 `Accept-Language`，用于用户手动选择。
- 后端统一 normalize locale。
- 不支持 locale 回退到 `zh-Hans`。

### 偏好接口

复用用户偏好接口：

`GET /health/preferences/me`

```json
{
  "localeMode": "manual",
  "locale": "zh-Hans",
  "weightUnit": "kg",
  "heightUnit": "cm",
  "energyUnit": "kcal"
}
```

`PUT /health/preferences/me`

```json
{
  "localeMode": "manual",
  "locale": "en",
  "weightUnit": "kg",
  "heightUnit": "cm",
  "energyUnit": "kcal"
}
```

### 错误响应

后端错误结构保持稳定：

```json
{
  "errorCode": "VALIDATION_FAILED",
  "message": "VALIDATION_FAILED",
  "fields": [
    { "field": "age", "code": "RANGE" }
  ]
}
```

说明：

- `message` 可保留调试文本，但客户端不直接展示。
- 客户端根据 `errorCode`、`field`、`code` 翻译。
- 需要服务端直出文案的场景，必须根据 normalized locale 选择模板。

### 生成类内容

AI 建议、报告摘要、通知内容、邮件短信模板需要 locale：

```json
{
  "id": "recommendation-id",
  "locale": "ja",
  "type": "water",
  "title": "...",
  "reason": "...",
  "generatedAt": "2026-05-19T10:00:00+08:00"
}
```

缓存 key 必须包含 locale：

```text
health:ai:recommendations:{userId}:{date}:{locale}
health:report:{userId}:{period}:{start}:{end}:{locale}
health:notification-template:{templateKey}:{locale}
```

## 7. 数据库设计

### `user_preferences`

扩展字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `locale_mode` | VARCHAR(20) | `system` / `manual` |
| `locale` | VARCHAR(20) | canonical locale |
| `weight_unit` | VARCHAR(10) | `kg` / `lb` |
| `height_unit` | VARCHAR(10) | `cm` / `ft_in` |
| `energy_unit` | VARCHAR(10) | `kcal` / `kj` |
| `updated_at` | TIMESTAMPTZ | 更新时间 |

约束：

- `locale` 允许值首期为 `zh-Hans`、`zh-Hant`、`en`、`ja`、`ko`。
- 旧值 `zh-CN` 读取时 normalize 为 `zh-Hans`，写回时统一存 canonical。

### Future：远程内容翻译

如运营配置、报告模板、AI 建议模板需要后台维护，可增加：

- `localized_content_templates`
- `localized_content_versions`

首期不建议把所有 UI 文案放数据库，避免发布和翻译流程复杂化。

## 8. UI 设计

### App 语言设置页

原型：`UI/app-language-settings.svg`

入口：

```text
我的 -> 设置与偏好 -> 语言与单位
```

页面内容：

- 跟随系统语言开关。
- 语言列表：中文简体、中文繁体、English、日本語、한국어。
- 当前语言标记。
- 切换语言后即时生效。
- 底部说明：新增语言后可通过资源包扩展。

### Web 语言设置页

原型：`UI/web-language-settings.svg`

入口：

```text
Web 工作台 -> 设置 -> 语言与单位
```

页面内容：

- 当前语言。
- 语言列表。
- Locale code 展示。
- 单位偏好。
- 保存按钮。

## 9. 扩展新语言流程

新增语言时：

1. 增加 canonical locale 到 `supportedLocales`。
2. 增加 Flutter ARB 文件。
3. 增加 Web locale JSON。
4. 增加后端 locale allowlist 和 alias 映射。
5. 增加生成类内容模板。
6. 增加 QA 截图和核心流程测试。
7. 检查长文案布局，特别是按钮、卡片、底部导航和图表标签。

新增语言不应修改业务 DTO、数据库业务表或健康指标枚举。

## 10. 验收标准

- App 可在中文简体、中文繁体、英文、日文、韩文之间切换。
- Web 可在中文简体、中文繁体、英文、日文、韩文之间切换。
- 未手动设置时跟随系统语言。
- 不支持系统语言时回退 `zh-Hans`。
- 用户手动选择语言后，重启 App 仍保持该语言。
- API 请求带 normalized locale。
- 后端存储 canonical locale。
- 错误提示通过客户端本地化展示。
- AI 建议和报告缓存包含 locale，切换语言后不复用旧语言缓存。
- 日期、数字、单位按 locale 和单位偏好展示。
- 新增语言只需要增加资源和 allowlist，不需要改业务逻辑。

## 11. 开发任务拆分

### 前端 App

1. 引入 `flutter_localizations` 和 `intl`。
2. 增加 `l10n.yaml` 和 5 个 ARB 文件。
3. 抽离硬编码中文文案。
4. 增加 `LocaleState` 和本地持久化。
5. 实现语言设置页。
6. API client 增加 `Accept-Language` / `X-Locale`。
7. 错误码映射为本地化文案。
8. 增加多语言 UI 回归。

### Web

1. 建立 locale JSON 资源目录。
2. 增加语言选择入口。
3. 抽离硬编码中文文案。
4. 日期、数字、单位统一走 formatter。
5. API 请求附带 locale。

### 后端

1. 增加 locale normalize 工具。
2. 扩展 `user_preferences`。
3. 偏好接口支持 `localeMode` 和 `locale`。
4. 生成类内容使用 normalized locale。
5. Redis key 加入 locale。
6. e2e 覆盖 locale 保存、回退和缓存隔离。

### QA

1. 5 种语言登录、建档、首页、我的、基本信息、语言设置主流程。
2. 长文本溢出检查。
3. locale 切换后缓存隔离。
4. 旧 `zh-CN` 数据迁移兼容。
