import {
  Body,
  Controller,
  Delete,
  Get,
  NotFoundException,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthTokenPayload } from '../auth/interfaces/auth.types';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateMyDietRecordDto } from './dto/create-my-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateMyExerciseRecordDto } from './dto/create-my-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { GetDietRecordHistoryQueryDto } from './dto/get-diet-record-history-query.dto';
import { GetExerciseRecordHistoryQueryDto } from './dto/get-exercise-record-history-query.dto';
import { GetHealthTrendQueryDto } from './dto/get-health-trend-query.dto';
import { UpsertMyProfileDto } from './dto/upsert-my-profile.dto';
import { HealthService } from './health.service';

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
  async getMyProfile(@CurrentUser() user: AuthTokenPayload) {
    const profile = await this.healthService.getProfile(user.sub);
    if (!profile) {
      throw new NotFoundException('profile not found');
    }
    return profile;
  }

  @Get('profiles/:userId')
  async getProfile(@Param('userId') userId: string) {
    return (await this.healthService.getProfile(userId)) ?? null;
  }

  @UseGuards(JwtAuthGuard)
  @Get('diet-records')
  getDietRecordHistory(
    @CurrentUser() user: AuthTokenPayload,
    @Query() query: GetDietRecordHistoryQueryDto,
  ) {
    return this.healthService.getDietRecordHistory(user.sub, query);
  }

  @UseGuards(JwtAuthGuard)
  @Get('exercise-records')
  getExerciseRecordHistory(
    @CurrentUser() user: AuthTokenPayload,
    @Query() query: GetExerciseRecordHistoryQueryDto,
  ) {
    return this.healthService.getExerciseRecordHistory(user.sub, query);
  }

  @Post('diet-records')
  addDietRecord(@Body() payload: CreateDietRecordDto) {
    return this.healthService.addDietRecord(payload);
  }

  @UseGuards(JwtAuthGuard)
  @Post('diet-records/me')
  addMyDietRecord(
    @CurrentUser() user: AuthTokenPayload,
    @Body() payload: CreateMyDietRecordDto,
  ) {
    return this.healthService.addMyDietRecord(user.sub, payload);
  }

  @UseGuards(JwtAuthGuard)
  @Get('diet-records/:id')
  async getDietRecordDetail(
    @CurrentUser() user: AuthTokenPayload,
    @Param('id') id: string,
  ) {
    const record = await this.healthService.getDietRecordDetail(user.sub, id);
    if (!record) {
      throw new NotFoundException('record not found');
    }
    return record;
  }

  @UseGuards(JwtAuthGuard)
  @Delete('diet-records/:id')
  async deleteDietRecord(
    @CurrentUser() user: AuthTokenPayload,
    @Param('id') id: string,
  ) {
    const result = await this.healthService.deleteDietRecord(user.sub, id);
    if (!result) {
      throw new NotFoundException('record not found');
    }
    return result;
  }

  @Post('exercise-records')
  addExerciseRecord(@Body() payload: CreateExerciseRecordDto) {
    return this.healthService.addExerciseRecord(payload);
  }

  @UseGuards(JwtAuthGuard)
  @Post('exercise-records/me')
  addMyExerciseRecord(
    @CurrentUser() user: AuthTokenPayload,
    @Body() payload: CreateMyExerciseRecordDto,
  ) {
    return this.healthService.addMyExerciseRecord(user.sub, payload);
  }

  @UseGuards(JwtAuthGuard)
  @Get('exercise-records/:id')
  async getExerciseRecordDetail(
    @CurrentUser() user: AuthTokenPayload,
    @Param('id') id: string,
  ) {
    const record = await this.healthService.getExerciseRecordDetail(user.sub, id);
    if (!record) {
      throw new NotFoundException('record not found');
    }
    return record;
  }

  @UseGuards(JwtAuthGuard)
  @Delete('exercise-records/:id')
  async deleteExerciseRecord(
    @CurrentUser() user: AuthTokenPayload,
    @Param('id') id: string,
  ) {
    const result = await this.healthService.deleteExerciseRecord(user.sub, id);
    if (!result) {
      throw new NotFoundException('record not found');
    }
    return result;
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

  @UseGuards(JwtAuthGuard)
  @Get('trends')
  getTrend(
    @CurrentUser() user: AuthTokenPayload,
    @Query() query: GetHealthTrendQueryDto,
  ) {
    return this.healthService.getTrend(user.sub, query);
  }

  @UseGuards(JwtAuthGuard)
  @Get('ai/recommendations/today')
  getTodayRecommendations(
    @CurrentUser() user: AuthTokenPayload,
    @Query('date') date = new Date().toISOString().slice(0, 10),
  ) {
    return this.healthService.getTodayRecommendations(user.sub, date);
  }

  @UseGuards(JwtAuthGuard)
  @Get('profile-center/me')
  async getProfileCenter(
    @CurrentUser() user: AuthTokenPayload,
    @Query('date') date = new Date().toISOString().slice(0, 10),
  ) {
    const profileCenter = await this.healthService.getProfileCenter(user.sub, date);
    if (!profileCenter) {
      throw new NotFoundException('profile not found');
    }
    return profileCenter;
  }
}
