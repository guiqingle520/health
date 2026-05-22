import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

jest.setTimeout(20000);

describe('HealthController (e2e)', () => {
  let app: INestApplication<App>;
  const phone = `138${Date.now().toString().slice(-8)}`;
  const secondPhone = `139${Date.now().toString().slice(-8)}`;

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

    const secondLoginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        phone: secondPhone,
        code: '123456',
      })
      .expect(201);

    const secondAccessToken = secondLoginResponse.body.accessToken as string;

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
      .post('/health/diet-records/me')
      .send({
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
      .expect(401);

    const lunchResponse = await request(app.getHttpServer())
      .post('/health/diet-records/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
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

    expect(lunchResponse.body).toHaveProperty('id');
    expect(lunchResponse.body).toHaveProperty('userId', userId);
    expect(lunchResponse.body).toHaveProperty('mealType', 'lunch');

    const lunchRecordId = lunchResponse.body.id as string;

    const breakfastResponse = await request(app.getHttpServer())
      .post('/health/diet-records/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        mealType: 'breakfast',
        foodName: '燕麦酸奶杯',
        nutrition: {
          calories: 280,
          carbs: 32,
          protein: 14,
          fat: 8,
          fiber: 5,
          sodiumMg: 180,
          calciumMg: 220,
          ironMg: 2.1,
          vitaminAMcg: 90,
          vitaminCMg: 12,
          vitaminDIU: 30,
        },
      })
      .expect(201);

    expect(breakfastResponse.body).toHaveProperty('id');
    const breakfastRecordId = breakfastResponse.body.id as string;

    await request(app.getHttpServer())
      .post('/health/exercise-records/me')
      .send({
        exerciseType: 'aerobic',
        durationMinutes: 40,
        caloriesBurned: 360,
      })
      .expect(401);

    const aerobicResponse = await request(app.getHttpServer())
      .post('/health/exercise-records/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        exerciseType: 'aerobic',
        durationMinutes: 40,
        caloriesBurned: 360,
      })
      .expect(201);

    expect(aerobicResponse.body).toHaveProperty('id');
    expect(aerobicResponse.body).toHaveProperty('userId', userId);
    expect(aerobicResponse.body).toHaveProperty('exerciseType', 'aerobic');
    expect(aerobicResponse.body).toHaveProperty('durationMinutes', 40);
    expect(aerobicResponse.body).toHaveProperty('caloriesBurned', 360);

    const aerobicRecordId = aerobicResponse.body.id as string;

    const strengthResponse = await request(app.getHttpServer())
      .post('/health/exercise-records/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        exerciseType: 'strength',
        durationMinutes: 25,
        caloriesBurned: 210,
      })
      .expect(201);

    expect(strengthResponse.body).toHaveProperty('id');
    const strengthRecordId = strengthResponse.body.id as string;

    await request(app.getHttpServer())
      .get('/health/diet-records')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(2);
        expect(res.body[0]).toHaveProperty('id');
        expect(res.body[0]).toHaveProperty('mealType');
        expect(res.body[0]).toHaveProperty('foodName');
        expect(res.body[0]).toHaveProperty('nutrition.calories');
      });

    await request(app.getHttpServer())
      .get('/health/diet-records?mealType=lunch')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toHaveProperty('id', lunchRecordId);
        expect(res.body[0]).toHaveProperty('mealType', 'lunch');
      });

    await request(app.getHttpServer())
      .get('/health/exercise-records?limit=5')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(2);
        expect(res.body[0]).toHaveProperty('id');
        expect(res.body[0]).toHaveProperty('exerciseType');
        expect(res.body[0]).toHaveProperty('durationMinutes');
        expect(res.body[0]).toHaveProperty('caloriesBurned');
      });

    await request(app.getHttpServer())
      .get('/health/exercise-records?exerciseType=strength')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toHaveProperty('id', strengthRecordId);
        expect(res.body[0]).toHaveProperty('exerciseType', 'strength');
      });

    await request(app.getHttpServer())
      .get(`/health/diet-records/${lunchRecordId}`)
      .expect(401);

    await request(app.getHttpServer())
      .delete(`/health/diet-records/${lunchRecordId}`)
      .expect(401);

    await request(app.getHttpServer())
      .get(`/health/exercise-records/${aerobicRecordId}`)
      .expect(401);

    await request(app.getHttpServer())
      .delete(`/health/exercise-records/${aerobicRecordId}`)
      .expect(401);

    await request(app.getHttpServer())
      .get(`/health/diet-records/${lunchRecordId}`)
      .set('Authorization', `Bearer ${secondAccessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/health/diet-records/${lunchRecordId}`)
      .set('Authorization', `Bearer ${secondAccessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .get(`/health/exercise-records/${aerobicRecordId}`)
      .set('Authorization', `Bearer ${secondAccessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/health/exercise-records/${aerobicRecordId}`)
      .set('Authorization', `Bearer ${secondAccessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .get(`/health/diet-records/${lunchRecordId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('id', lunchRecordId);
        expect(res.body).toHaveProperty('foodName', '鸡胸肉沙拉');
        expect(res.body).toHaveProperty('nutrition.protein', 35);
      });

    await request(app.getHttpServer())
      .get(`/health/exercise-records/${aerobicRecordId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('id', aerobicRecordId);
        expect(res.body).toHaveProperty('exerciseType', 'aerobic');
        expect(res.body).toHaveProperty('durationMinutes', 40);
        expect(res.body).toHaveProperty('caloriesBurned', 360);
      });

    await request(app.getHttpServer())
      .get('/health/diet-records')
      .expect(401);

    await request(app.getHttpServer())
      .get(`/health/daily-summary/${userId}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('intake.calories', 700);
        expect(res.body).toHaveProperty('intake.protein', 49);
        expect(res.body).toHaveProperty('burnedCalories', 570);
      });

    await request(app.getHttpServer())
      .get('/health/dashboard/today')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('profile.nickname', '测试用户');
        expect(res.body).toHaveProperty('summary.intake.calories', 700);
        expect(res.body).toHaveProperty('summary.burnedCalories', 570);
      });

    await request(app.getHttpServer()).get('/health/trends').expect(401);

    await request(app.getHttpServer())
      .get('/health/trends?metric=weight&period=week')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('metric', 'weight');
        expect(res.body).toHaveProperty('period', 'week');
        expect(res.body).toHaveProperty('currentValue');
        expect(res.body).toHaveProperty('points');
        expect(res.body.points.length).toBeGreaterThan(0);
        expect(res.body).toHaveProperty('signals');
        expect(res.body.signals[0]).toHaveProperty('message');
      });

    await request(app.getHttpServer())
      .get('/health/ai/recommendations/today')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('date');
        expect(res.body).toHaveProperty('items');
        expect(res.body.items.length).toBeGreaterThan(0);
        expect(res.body.items[0]).toHaveProperty('id');
        expect(res.body.items[0]).toHaveProperty('type');
        expect(res.body.items[0]).toHaveProperty('title');
        expect(res.body.items[0]).toHaveProperty('reason');
        expect(res.body.items[0]).toHaveProperty('actionText');
        expect(res.body.items[0]).toHaveProperty('status', 'pending');
      });

    await request(app.getHttpServer())
      .get('/health/profile-center/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('profile.nickname', '测试用户');
        expect(res.body).toHaveProperty('stats.healthScore');
        expect(res.body).toHaveProperty('pro.title', 'HealthGuard Pro');
        expect(res.body).toHaveProperty('sections');
        expect(res.body.sections.length).toBeGreaterThan(0);
      });

    await request(app.getHttpServer())
      .delete(`/health/diet-records/${breakfastRecordId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toEqual({ success: true });
      });

    await request(app.getHttpServer())
      .get(`/health/diet-records/${breakfastRecordId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .get('/health/diet-records')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toHaveProperty('id', lunchRecordId);
      });

    await request(app.getHttpServer())
      .delete(`/health/exercise-records/${strengthRecordId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toEqual({ success: true });
      });

    await request(app.getHttpServer())
      .get(`/health/exercise-records/${strengthRecordId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .get('/health/exercise-records')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveLength(1);
        expect(res.body[0]).toHaveProperty('id', aerobicRecordId);
      });
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });
});
