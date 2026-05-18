import { Injectable } from '@nestjs/common';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { GetRecordHistoryQueryDto } from './dto/get-record-history-query.dto';
import { UpsertMyProfileDto } from './dto/upsert-my-profile.dto';
import {
  DailySummary,
  DashboardView,
  DietRecordHistoryItem,
  ExerciseRecordHistoryItem,
} from './interfaces/health.types';
import { HealthRepository } from './health.repository';

@Injectable()
export class HealthService {
  constructor(private readonly healthRepository: HealthRepository) {}

  saveProfile(payload: CreateProfileDto): Promise<CreateProfileDto> {
    return this.healthRepository.upsertProfile(payload.id, {
      nickname: payload.nickname,
      age: payload.age,
      gender: payload.gender,
      heightCm: payload.heightCm,
      weightKg: payload.weightKg,
      goal: payload.goal,
    });
  }

  upsertMyProfile(
    userId: string,
    payload: UpsertMyProfileDto,
  ): Promise<CreateProfileDto> {
    return this.healthRepository.upsertProfile(userId, payload);
  }

  getProfile(userId: string): Promise<CreateProfileDto | undefined> {
    return this.healthRepository.findProfileByUserId(userId);
  }

  async getDashboard(userId: string, date: string): Promise<DashboardView> {
    const summary = await this.getDailySummary(userId, date);
    const profile = await this.getProfile(userId);
    const healthScore = this.calculateHealthScore(summary);

    return {
      date,
      healthScore,
      profile: profile
        ? {
            nickname: profile.nickname,
            goal: profile.goal,
          }
        : null,
      cards: {
        steps: 8234,
        stepTarget: 10000,
        sleepHours: 7.2,
        sleepScore: 85,
        waterMl: 1200,
        waterTargetMl: 2000,
        calories: summary.intake.calories,
        calorieTarget: 2200,
      },
      aiInsights: this.buildInsights(summary),
      summary,
    };
  }

  async getDietRecordHistory(
    userId: string,
    query: GetRecordHistoryQueryDto,
  ): Promise<DietRecordHistoryItem[]> {
    const { from, to, limit } = this.normalizeHistoryQuery(query);
    return this.healthRepository.findDietRecordsByUserIdAndDateRange(
      userId,
      from,
      to,
      limit,
    );
  }

  async getExerciseRecordHistory(
    userId: string,
    query: GetRecordHistoryQueryDto,
  ): Promise<ExerciseRecordHistoryItem[]> {
    const { from, to, limit } = this.normalizeHistoryQuery(query);
    return this.healthRepository.findExerciseRecordsByUserIdAndDateRange(
      userId,
      from,
      to,
      limit,
    );
  }

  addDietRecord(
    payload: CreateDietRecordDto,
  ): Promise<CreateDietRecordDto & { date: string }> {
    const date = new Date().toISOString().slice(0, 10);
    return this.healthRepository.insertDietRecord(payload, date);
  }

  addExerciseRecord(
    payload: CreateExerciseRecordDto,
  ): Promise<CreateExerciseRecordDto & { date: string }> {
    const date = new Date().toISOString().slice(0, 10);
    return this.healthRepository.insertExerciseRecord(payload, date);
  }

  async getDailySummary(userId: string, date: string): Promise<DailySummary> {
    const [intake, burnedCalories] = await Promise.all([
      this.healthRepository.getDailyNutritionTotals(userId, date),
      this.healthRepository.getDailyBurnedCalories(userId, date),
    ]);

    return {
      date,
      intake,
      burnedCalories,
      suggestion:
        intake.protein < 60
          ? '今日蛋白质偏低，建议补充鸡蛋、鱼类或豆制品。'
          : '营养结构较均衡，继续保持。',
    };
  }

  private calculateHealthScore(summary: DailySummary): number {
    const proteinScore = Math.min(summary.intake.protein / 80, 1) * 25;
    const fiberScore = Math.min(summary.intake.fiber / 25, 1) * 20;
    const activityScore = Math.min(summary.burnedCalories / 600, 1) * 30;
    const calorieBalanceScore =
      summary.intake.calories <= 2200 && summary.intake.calories >= 1200
        ? 25
        : 10;

    return Math.round(
      Math.max(
        0,
        Math.min(
          proteinScore + fiberScore + activityScore + calorieBalanceScore,
          100,
        ),
      ),
    );
  }

  private normalizeHistoryQuery(query: GetRecordHistoryQueryDto): {
    from: string;
    to: string;
    limit: number;
  } {
    const today = new Date().toISOString().slice(0, 10);
    const to = query.to ?? today;
    const endDate = new Date(`${to}T00:00:00.000Z`);
    const defaultFromDate = new Date(endDate);
    defaultFromDate.setUTCDate(defaultFromDate.getUTCDate() - 29);

    const from = query.from ?? defaultFromDate.toISOString().slice(0, 10);
    const limit = Math.min(query.limit ?? 50, 100);

    return {
      from,
      to,
      limit,
    };
  }

  private buildInsights(summary: DailySummary): string[] {
    const insights: string[] = [];

    if (summary.intake.protein < 60) {
      insights.push('今日蛋白质偏低，建议补充鸡蛋、鱼类或豆制品。');
    } else {
      insights.push('本日蛋白质摄入达标，保持当前饮食结构。');
    }

    if (summary.burnedCalories < 250) {
      insights.push('运动消耗较少，建议增加 20-30 分钟有氧活动。');
    } else {
      insights.push('今日运动量表现良好，继续保持。');
    }

    return insights;
  }
}
