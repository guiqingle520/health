import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { UpsertMyProfileDto } from './dto/upsert-my-profile.dto';
import { HealthService } from './health.service';
import type { AuthTokenPayload } from '../auth/interfaces/auth.types';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Post('profiles')
  saveProfile(@Body() payload: CreateProfileDto) {
    return this.healthService.saveProfile(payload);
  }

  @UseGuards(JwtAuthGuard)
  @Post('profiles/me')
  upsertMyProfile(
    @CurrentUser() user: AuthTokenPayload,
    @Body() payload: UpsertMyProfileDto,
  ) {
    return this.healthService.upsertMyProfile(user.sub, payload);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profiles/me')
  getMyProfile(@CurrentUser() user: AuthTokenPayload) {
    const profile = this.healthService.getProfile(user.sub);
    if (!profile) {
      throw new NotFoundException('profile not found');
    }
    return profile;
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

  @UseGuards(JwtAuthGuard)
  @Get('dashboard/today')
  getDashboard(
    @CurrentUser() user: AuthTokenPayload,
    @Query('date') date = new Date().toISOString().slice(0, 10),
  ) {
    return this.healthService.getDashboard(user.sub, date);
  }
}
