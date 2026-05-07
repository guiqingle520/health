import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('HealthController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/health/daily-summary/:userId (GET)', () => {
    return request(app.getHttpServer())
      .get('/health/daily-summary/user-1?date=2026-05-07')
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('date', '2026-05-07');
        expect(res.body).toHaveProperty('intake');
      });
  });

  afterEach(async () => {
    await app.close();
  });
});
