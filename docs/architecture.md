# Health App Architecture

## Monorepo

- `apps/mobile`: Flutter 客户端（Android / iOS / Web）。
- `apps/backend`: NestJS 后端（REST + WebSocket）。
- `packages/shared`: 共享类型定义。
- `docs`: 架构与交付文档。

## MVP 范围（Phase 1）

1. 用户注册/登录与个人资料管理。
2. 饮食记录与营养汇总。
3. 运动记录与消耗汇总。
4. 日度卡路里与宏量营养仪表盘。

## 后续阶段

- Phase 2: AI 识别、AI 建议、自然语言记录、周/月报。
- Phase 3: 社交能力、可穿戴设备、专家咨询与 PC 报表。
