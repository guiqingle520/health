import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

jest.setTimeout(20000);

describe('HealthController (e2e)', () => {
  let app: INestApplication<App>;
  const phone = `138${Date.now().toString().slice(-8)}`;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    app.enableShutdownHooks();
    await app.init();
  });

  it('/health daily flow works with PostgreSQL-backed UUID users', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        phone,
        code: '123456',
      })
      .expect(201);

    expect(loginResponse.body).toHaveProperty('user.id');
    expect(loginResponse.body).toHaveProperty('accessToken');
    expect(loginResponse.body).toHaveProperty('refreshToken');

    const accessToken = loginResponse.body.accessToken as string;
    const userId = loginResponse.body.user.id as string;

    await request(app.getHttpServer())
      .get('/health/profiles/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .post('/health/profiles/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        nickname: '测试用户',
        age: 30,
        gender: 'male',
        heightCm: 175,
        weightKg: 72,
        goal: 'maintain',
      })
      .expect(201)
      .expect((res) => {
        expect(res.body).toHaveProperty('id', userId);
        expect(res.body).toHaveProperty('nickname', '测试用户');
      });

    await request(app.getHttpServer())
      .post('/health/diet-records')
      .send({
        userId,
        mealType: 'lunch',
        foodName: '鸡胸肉沙拉',
        nutrition: {
          calories: 420,
          carbs: 18,
          protein: 35,
          fat: 14,
          fiber: 6,
          sodiumMg: 520,
          calciumMg: 110,
          ironMg: 3.2,
          vitaminAMcg: 180,
          vitaminCMg: 25,
          vitaminDIU: 40,
        },
      })
      .expect(201);

    await request(app.getHttpServer())
      .post('/health/exercise-records')
      .send({
        userId,
        exerciseType: 'aerobic',
        durationMinutes: 40,
        caloriesBurned: 360,
      })
      .expect(201);

    await request(app.getHttpServer())
      .get('/health/diet-records')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toHaveProperty('mealType', 'lunch');
        expect(res.body[0]).toHaveProperty('foodName', '鸡胸肉沙拉');
        expect(res.body[0]).toHaveProperty('nutrition.calories', 420);
      });

    await request(app.getHttpServer())
      .get('/health/exercise-records?limit=1')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toHaveProperty('exerciseType', 'aerobic');
        expect(res.body[0]).toHaveProperty('durationMinutes', 40);
        expect(res.body[0]).toHaveProperty('caloriesBurned', 360);
      });

    await request(app.getHttpServer())
      .get('/health/diet-records')
      .expect(401);

    await request(app.getHttpServer())
      .get(`/health/daily-summary/${userId}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('intake.calories', 420);
        expect(res.body).toHaveProperty('intake.protein', 35);
        expect(res.body).toHaveProperty('burnedCalories', 360);
      });

    await request(app.getHttpServer())
      .get('/health/dashboard/today')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('profile.nickname', '测试用户');
        expect(res.body).toHaveProperty('summary.intake.calories', 420);
        expect(res.body).toHaveProperty('summary.burnedCalories', 360);
      });
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });
});
