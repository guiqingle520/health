import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health/health.controller';
import { HealthService } from './health/health.service';

describe('HealthController', () => {
  let healthController: HealthController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [HealthService],
    }).compile();

    healthController = app.get<HealthController>(HealthController);
  });

  it('should return default summary shape', () => {
    const summary = healthController.getDailySummary('user-1', '2026-05-07');
    expect(summary.date).toBe('2026-05-07');
    expect(summary.intake.calories).toBe(0);
    expect(summary.burnedCalories).toBe(0);
  });
});
