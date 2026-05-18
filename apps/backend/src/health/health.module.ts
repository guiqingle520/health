import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { HealthController } from './health.controller';
import { HealthRepository } from './health.repository';
import { HealthService } from './health.service';

@Module({
  imports: [DatabaseModule],
  controllers: [HealthController],
  providers: [HealthRepository, HealthService],
})
export class HealthModule {}
