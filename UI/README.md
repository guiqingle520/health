# UI 原型归档

本目录为 HealthGuard App 与 Web 端原型图归档，依据：

- `docs/04-ui/mobile-ui-design.md`
- `docs/04-ui/web-ui-design.md`
- `docs/reference/companion-context.md`

## 文件

- `index.html`：原型总览页面
- `ui-prototype-board.svg`：App/Web 总览画板
- `app-login.svg`：App 登录页
- `app-onboarding.svg`：App 建档页
- `app-dashboard.svg`：App 仪表盘页
- `app-profile.svg`：App 我的 / 个人中心长页面
- `app-records.svg`：App 记录中心页
- `app-report.svg`：App 健康报告页
- `app-garmin-connect.svg`：App Garmin 未连接 / 授权页
- `app-garmin-status.svg`：App Garmin 已连接 / 同步状态页
- `app-family-share.svg`：App 家庭共享页
- `app-pro-ecosystem.svg`：App Pro 会员与生态预留页
- `app-ai-advice.svg`：App AI 健康建议页
- `app-data.svg`：App 数据趋势页
- `app-notification-goals.svg`：App 通知提醒和目标设定页
- `web-login.svg`：Web 登录页
- `web-onboarding.svg`：Web 建档页
- `web-dashboard.svg`：Web 今日健康仪表盘
- `web-notification-goals.svg`：Web 通知提醒和目标设定页

## 设计覆盖

- 主路径：登录、建档、仪表盘
- 功能页：数据趋势、AI 健康建议、我的 / 个人中心
- 设置页：通知提醒和目标设定、语言与单位
- 视觉基调：蓝绿主色、清爽可信、轻医疗感
- 组件风格：卡片式布局、大按钮、大字号表单、清晰分区
- Companion context：以“陪伴摘要 / 陪伴上下文”形式附着在仪表盘和 AI 洞察中，不作为独立宠物业务入口

直接打开 `index.html` 即可查看完整归档。

## 参考风格衍生

App 端已统一采用用户功能页参考图的视觉语言：深绿机身边框、浅绿灰页面背景、白色大圆角卡片、青绿色高亮、浅薄投影与底部胶囊导航。登录、建档、仪表盘、数据趋势、AI 建议和个人中心已使用同一套样式。

## 新增 App 功能页

根据用户粘贴的参考图新增三类底部导航页面：

- 数据趋势：周/月/年切换、体重趋势、静息心率趋势与异常提示
- AI 健康建议：拍照记录饮食、AI 搜索入口、今日推荐建议卡片
- 我的：个人资料、会员入口、健康档案、数据报告、家庭共享、设置偏好、帮助支持与退出登录

## 开发计划扩展页

根据 `docs/03-technical/development-plan.md` 的 18 周开发计划，补充记录中心、健康报告、Garmin 接入、家庭共享、Pro 会员与设备生态预留等页面，用于第 6-18 周开发评审。
