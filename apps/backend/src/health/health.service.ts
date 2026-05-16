import { Injectable } from '@nestjs/common';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { UpsertMyProfileDto } from './dto/upsert-my-profile.dto';
import {
  DailySummary,
  DashboardView,
  NutritionMetrics,
} from './interfaces/health.types';

@Injectable()
export class HealthService {
  private readonly profiles = new Map<string, CreateProfileDto>();
  private readonly dietRecords: Array<CreateDietRecordDto & { date: string }> =
    [];
  private readonly exerciseRecords: Array<
    CreateExerciseRecordDto & { date: string }
  > = [];

  saveProfile(payload: CreateProfileDto): CreateProfileDto {
    this.profiles.set(payload.id, payload);
    return payload;
  }

  upsertMyProfile(
    userId: string,
    payload: UpsertMyProfileDto,
  ): CreateProfileDto {
    const profile: CreateProfileDto = {
      id: userId,
      ...payload,
    };

    this.profiles.set(userId, profile);
    return profile;
  }

  getProfile(userId: string): CreateProfileDto | undefined {
    return this.profiles.get(userId);
  }

  getDashboard(userId: string, date: string): DashboardView {
    const summary = this.getDailySummary(userId, date);
    const profile = this.getProfile(userId);
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

  addDietRecord(
    payload: CreateDietRecordDto,
  ): CreateDietRecordDto & { date: string } {
    const record = {
      ...payload,
      date: new Date().toISOString().slice(0, 10),
    };
    this.dietRecords.push(record);
    return record;
  }

  addExerciseRecord(
    payload: CreateExerciseRecordDto,
  ): CreateExerciseRecordDto & { date: string } {
    const record = {
      ...payload,
      date: new Date().toISOString().slice(0, 10),
    };
    this.exerciseRecords.push(record);
    return record;
  }

  getDailySummary(userId: string, date: string): DailySummary {
    const intake = this.dietRecords
      .filter((record) => record.userId === userId && record.date === date)
      .reduce<NutritionMetrics>(
        (acc, record) => ({
          calories: acc.calories + record.nutrition.calories,
          carbs: acc.carbs + record.nutrition.carbs,
          protein: acc.protein + record.nutrition.protein,
          fat: acc.fat + record.nutrition.fat,
          fiber: acc.fiber + record.nutrition.fiber,
          sodiumMg: acc.sodiumMg + record.nutrition.sodiumMg,
          calciumMg: acc.calciumMg + record.nutrition.calciumMg,
          ironMg: acc.ironMg + record.nutrition.ironMg,
          vitaminAMcg: acc.vitaminAMcg + record.nutrition.vitaminAMcg,
          vitaminCMg: acc.vitaminCMg + record.nutrition.vitaminCMg,
          vitaminDIU: acc.vitaminDIU + record.nutrition.vitaminDIU,
        }),
        {
          calories: 0,
          carbs: 0,
          protein: 0,
          fat: 0,
          fiber: 0,
          sodiumMg: 0,
          calciumMg: 0,
          ironMg: 0,
          vitaminAMcg: 0,
          vitaminCMg: 0,
          vitaminDIU: 0,
        },
      );

    const burnedCalories = this.exerciseRecords
      .filter((record) => record.userId === userId && record.date === date)
      .reduce((sum, record) => sum + record.caloriesBurned, 0);

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
