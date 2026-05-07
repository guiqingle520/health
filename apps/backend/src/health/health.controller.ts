import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Post('profiles')
  saveProfile(@Body() payload: CreateProfileDto) {
    return this.healthService.saveProfile(payload);
  }

  @Get('profiles/:userId')
  getProfile(@Param('userId') userId: string) {
    return this.healthService.getProfile(userId) ?? null;
  }

  @Post('diet-records')
  addDietRecord(@Body() payload: CreateDietRecordDto) {
    return this.healthService.addDietRecord(payload);
  }

  @Post('exercise-records')
  addExerciseRecord(@Body() payload: CreateExerciseRecordDto) {
    return this.healthService.addExerciseRecord(payload);
  }

  @Get('daily-summary/:userId')
  getDailySummary(
    @Param('userId') userId: string,
    @Query('date') date = new Date().toISOString().slice(0, 10),
  ) {
    return this.healthService.getDailySummary(userId, date);
  }
}
