# API 设计

本文档基于当前 NestJS 后端实现整理 API 规范，覆盖认证、用户档案、饮食记录、运动记录、日汇总与仪表盘接口。

## 1. 基础约定

- Base URL：`/`
- 风格：REST JSON API
- 鉴权方式：Bearer Token
- 响应格式：当前实现直接返回 JSON 对象，后续如需统一包装可再演进

## 2. 认证接口

### 2.1 登录

**POST** `/auth/login`

用途：

- 使用手机号与验证码登录
- 首次登录时可自动创建用户
- 返回 access token 与 refresh token

请求示例：

```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

响应说明：

- access token
- refresh token
- 用户基础信息

代码入口：`apps/backend/src/auth/auth.controller.ts`

### 2.2 获取当前用户

**GET** `/auth/me`

请求头：

```http
Authorization: Bearer <access_token>
```

用途：

- 校验当前 token 是否有效
- 获取当前登录用户信息

### 2.3 刷新 token

**POST** `/auth/refresh`

请求头：

```http
Authorization: Bearer <access_token>
```

请求示例：

```json
{
  "refreshToken": "xxx"
}
```

用途：

- 使用 refresh token 换取新的 token

## 3. 健康档案接口

控制器入口：`apps/backend/src/health/health.controller.ts`

### 3.1 创建或保存指定用户档案

**POST** `/health/profiles`

用途：

- 保存指定用户完整档案
- 更适合后台导入或非当前登录态使用

请求体字段：

```json
{
  "id": "user-uuid",
  "nickname": "张先生",
  "age": 30,
  "gender": "male",
  "heightCm": 175,
  "weightKg": 72,
  "goal": "maintain"
}
```

### 3.2 当前用户建档或更新档案

**POST** `/health/profiles/me`

请求头：

```http
Authorization: Bearer <access_token>
```

用途：

- 首次建档
- 更新当前用户档案

请求体字段：

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

### 3.3 获取当前用户档案

**GET** `/health/profiles/me`

请求头：

```http
Authorization: Bearer <access_token>
```

返回：

- 存在档案时返回完整档案对象
- 不存在时返回 404

### 3.4 获取指定用户档案

**GET** `/health/profiles/:userId`

用途：

- 根据用户 ID 查询档案
- 当前实现未加鉴权，后续建议视业务收紧权限

## 4. 饮食记录接口

### 4.1 新增饮食记录

**POST** `/health/diet-records`

用途：

- 写入单条饮食记录
- 当前服务会自动补当天日期字段

请求体示例：

```json
{
  "userId": "user-uuid",
  "mealType": "lunch",
  "foodName": "鸡胸肉沙拉",
  "nutrition": {
    "calories": 420,
    "carbs": 18,
    "protein": 35,
    "fat": 14,
    "fiber": 6,
    "sodiumMg": 520,
    "calciumMg": 110,
    "ironMg": 3.2,
    "vitaminAMcg": 180,
    "vitaminCMg": 25,
    "vitaminDIU": 40
  }
}
```

## 5. 运动记录接口

### 5.1 新增运动记录

**POST** `/health/exercise-records`

请求体示例：

```json
{
  "userId": "user-uuid",
  "exerciseType": "running",
  "durationMinutes": 40,
  "caloriesBurned": 360
}
```

## 6. 汇总与仪表盘接口

### 6.1 获取日汇总

**GET** `/health/daily-summary/:userId?date=YYYY-MM-DD`

用途：

- 汇总指定用户指定日期的营养摄入与运动消耗
- 若未传 date，默认使用当天

返回内容包括：

- `date`
- `intake`
- `burnedCalories`
- `suggestion`

### 6.2 获取今日仪表盘

**GET** `/health/dashboard/today?date=YYYY-MM-DD`

请求头：

```http
Authorization: Bearer <access_token>
```

用途：

- 获取当前用户某日仪表盘
- 返回健康分数、档案摘要、卡片数据、AI 洞察、日汇总

返回结构示意：

```json
{
  "date": "2026-05-16",
  "healthScore": 82,
  "profile": {
    "nickname": "张先生",
    "goal": "maintain"
  },
  "cards": {
    "steps": 8234,
    "stepTarget": 10000,
    "sleepHours": 7.2,
    "sleepScore": 85,
    "waterMl": 1200,
    "waterTargetMl": 2000,
    "calories": 1850,
    "calorieTarget": 2200
  },
  "aiInsights": [
    "本日蛋白质摄入达标，保持当前饮食结构。",
    "今日运动量表现良好，继续保持。"
  ],
  "summary": {
    "date": "2026-05-16",
    "intake": {
      "calories": 1850,
      "carbs": 170,
      "protein": 88,
      "fat": 54,
      "fiber": 24,
      "sodiumMg": 1800,
      "calciumMg": 700,
      "ironMg": 14,
      "vitaminAMcg": 500,
      "vitaminCMg": 90,
      "vitaminDIU": 120
    },
    "burnedCalories": 360,
    "suggestion": "营养结构较均衡，继续保持。"
  }
}
```

## 7. 当前实现特点

### 7.1 优点

- 控制器边界清晰
- 认证与健康模块分离
- 当前移动端主路径已能直接对接这些接口

### 7.2 当前限制

- 饮食与运动写入接口未加鉴权
- 返回体尚未统一错误码与错误结构
- 缺少分页、批量写入、删除与更新接口
- 记录日期当前由服务端使用当天生成，后续可支持客户端传入历史日期

## 8. 建议的下一步 API 演进

建议按优先级补充：

1. `PUT /health/profiles/me` 或保持 `POST` 但语义明确为 upsert
2. 为饮食与运动记录增加鉴权
3. 增加查询记录列表接口
4. 增加批量记录接口
5. 增加周报 / 月报接口
6. 增加 AI 分析接口

## 9. 对应代码位置

- `apps/backend/src/auth/auth.controller.ts`
- `apps/backend/src/auth/auth.service.ts`
- `apps/backend/src/health/health.controller.ts`
- `apps/backend/src/health/health.service.ts`
- `apps/backend/src/health/interfaces/health.types.ts`
