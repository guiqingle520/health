# Health Backend (NestJS)

MVP 后端提供以下能力：

- 用户资料写入与读取
- 饮食记录写入
- 运动记录写入
- 日度营养汇总（摄入 + 消耗 + AI建议占位）

## API

- `POST /health/profiles`
- `GET /health/profiles/:userId`
- `POST /health/diet-records`
- `POST /health/exercise-records`
- `GET /health/daily-summary/:userId?date=YYYY-MM-DD`

## Run

```bash
npm install
npm run start:dev
```
