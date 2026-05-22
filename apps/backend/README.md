# Health Backend (NestJS)

MVP 后端提供以下能力：

- 鉴权登录（JWT）
- 用户资料写入与读取（含 onboarding 场景）
- 饮食记录写入
- 运动记录写入
- 日度营养汇总与 dashboard 聚合（摄入 + 消耗 + AI建议占位）

## API

- `POST /auth/login`
- `GET /auth/me` (Bearer Token)
- `POST /auth/refresh` (Bearer Token)
- `POST /health/profiles`
- `POST /health/profiles/me` (Bearer Token)
- `GET /health/profiles/:userId`
- `GET /health/profiles/me` (Bearer Token)
- `POST /health/diet-records`
- `POST /health/exercise-records`
- `GET /health/daily-summary/:userId?date=YYYY-MM-DD`
- `GET /health/dashboard/today?date=YYYY-MM-DD` (Bearer Token)

## 数据模型（M1 + M2）

- `apps/backend/sql/m1_m2_schema.sql` 提供 users、user_profiles、refresh_tokens 的初始化表结构。

## Run

```bash
npm install
npm run start:dev
```
