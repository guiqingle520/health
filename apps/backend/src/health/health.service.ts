import { Injectable } from '@nestjs/common';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { DailySummary, NutritionMetrics } from './interfaces/health.types';

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

  getProfile(userId: string): CreateProfileDto | undefined {
    return this.profiles.get(userId);
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
}
