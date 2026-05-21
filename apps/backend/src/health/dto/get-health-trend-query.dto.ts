import { IsIn, IsOptional } from 'class-validator';
import type { HealthTrendMetric, HealthTrendPeriod } from '../interfaces/health.types';

export class GetHealthTrendQueryDto {
  @IsOptional()
  @IsIn(['weight', 'score', 'heartRate', 'calories', 'water', 'sleep'])
  metric?: HealthTrendMetric;

  @IsOptional()
  @IsIn(['week', 'month', 'year'])
  period?: HealthTrendPeriod;
}
