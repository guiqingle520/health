import { Inject, Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { Pool, QueryResult } from 'pg';
import { DATABASE_POOL } from '../database/database.constants';
import { CreateDietRecordDto } from './dto/create-diet-record.dto';
import { CreateExerciseRecordDto } from './dto/create-exercise-record.dto';
import { CreateProfileDto } from './dto/create-profile.dto';
import { UpsertMyProfileDto } from './dto/upsert-my-profile.dto';
import { DietRecordHistoryItem, ExerciseRecordHistoryItem, NutritionMetrics } from './interfaces/health.types';

type ProfileRow = {
  user_id: string;
  nickname: string;
  age: number;
  gender: 'male' | 'female';
  height_cm: number | string;
  weight_kg: number | string;
  goal: 'lose_fat' | 'gain_muscle' | 'maintain';
};

type DietAggregateRow = {
  calories: number | string;
  carbs: number | string;
  protein: number | string;
  fat: number | string;
  fiber: number | string;
  sodium_mg: number | string;
  calcium_mg: number | string;
  iron_mg: number | string;
  vitamin_a_mcg: number | string;
  vitamin_c_mg: number | string;
  vitamin_d_iu: number | string;
};

type DietHistoryRow = {
  meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  food_name: string;
  recorded_on: string;
} & DietAggregateRow;

type ExerciseAggregateRow = {
  burned_calories: number | string;
};

type ExerciseHistoryRow = {
  exercise_type: 'aerobic' | 'strength' | 'flexibility';
  duration_minutes: number;
  calories_burned: number | string;
  recorded_on: string;
};

@Injectable()
export class HealthRepository {
  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  async upsertProfile(
    userId: string,
    payload: Omit<CreateProfileDto, 'id'>,
  ): Promise<CreateProfileDto> {
    const result = await this.pool.query<ProfileRow>(
      `INSERT INTO user_profiles (
         user_id,
         nickname,
         age,
         gender,
         height_cm,
         weight_kg,
         goal
       ) VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (user_id)
       DO UPDATE SET
         nickname = EXCLUDED.nickname,
         age = EXCLUDED.age,
         gender = EXCLUDED.gender,
         height_cm = EXCLUDED.height_cm,
         weight_kg = EXCLUDED.weight_kg,
         goal = EXCLUDED.goal,
         updated_at = NOW()
       RETURNING user_id, nickname, age, gender, height_cm, weight_kg, goal`,
      [
        userId,
        payload.nickname,
        payload.age,
        payload.gender,
        payload.heightCm,
        payload.weightKg,
        payload.goal,
      ],
    );

    return this.mapProfile(result.rows[0]);
  }

  async findProfileByUserId(userId: string): Promise<CreateProfileDto | undefined> {
    const result = await this.pool.query<ProfileRow>(
      `SELECT user_id, nickname, age, gender, height_cm, weight_kg, goal
       FROM user_profiles
       WHERE user_id = $1`,
      [userId],
    );

    const row = result.rows[0];
    return row ? this.mapProfile(row) : undefined;
  }

  async insertDietRecord(
    payload: CreateDietRecordDto,
    date: string,
  ): Promise<CreateDietRecordDto & { date: string }> {
    await this.pool.query(
      `INSERT INTO diet_records (
         id,
         user_id,
         meal_type,
         food_name,
         recorded_on,
         calories,
         carbs,
         protein,
         fat,
         fiber,
         sodium_mg,
         calcium_mg,
         iron_mg,
         vitamin_a_mcg,
         vitamin_c_mg,
         vitamin_d_iu
       ) VALUES (
         $1, $2, $3, $4, $5,
         $6, $7, $8, $9, $10,
         $11, $12, $13, $14, $15, $16
       )`,
      [
        randomUUID(),
        payload.userId,
        payload.mealType,
        payload.foodName,
        date,
        payload.nutrition.calories,
        payload.nutrition.carbs,
        payload.nutrition.protein,
        payload.nutrition.fat,
        payload.nutrition.fiber,
        payload.nutrition.sodiumMg,
        payload.nutrition.calciumMg,
        payload.nutrition.ironMg,
        payload.nutrition.vitaminAMcg,
        payload.nutrition.vitaminCMg,
        payload.nutrition.vitaminDIU,
      ],
    );

    return {
      ...payload,
      date,
    };
  }

  async insertExerciseRecord(
    payload: CreateExerciseRecordDto,
    date: string,
  ): Promise<CreateExerciseRecordDto & { date: string }> {
    await this.pool.query(
      `INSERT INTO exercise_records (
         id,
         user_id,
         exercise_type,
         duration_minutes,
         calories_burned,
         recorded_on
       ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        randomUUID(),
        payload.userId,
        payload.exerciseType,
        payload.durationMinutes,
        payload.caloriesBurned,
        date,
      ],
    );

    return {
      ...payload,
      date,
    };
  }

  async getDailyNutritionTotals(
    userId: string,
    date: string,
  ): Promise<NutritionMetrics> {
    const result = await this.pool.query<DietAggregateRow>(
      `SELECT
         COALESCE(SUM(calories), 0) AS calories,
         COALESCE(SUM(carbs), 0) AS carbs,
         COALESCE(SUM(protein), 0) AS protein,
         COALESCE(SUM(fat), 0) AS fat,
         COALESCE(SUM(fiber), 0) AS fiber,
         COALESCE(SUM(sodium_mg), 0) AS sodium_mg,
         COALESCE(SUM(calcium_mg), 0) AS calcium_mg,
         COALESCE(SUM(iron_mg), 0) AS iron_mg,
         COALESCE(SUM(vitamin_a_mcg), 0) AS vitamin_a_mcg,
         COALESCE(SUM(vitamin_c_mg), 0) AS vitamin_c_mg,
         COALESCE(SUM(vitamin_d_iu), 0) AS vitamin_d_iu
       FROM diet_records
       WHERE user_id = $1 AND recorded_on = $2`,
      [userId, date],
    );

    const row = result.rows[0];
    return {
      calories: this.toNumber(row?.calories),
      carbs: this.toNumber(row?.carbs),
      protein: this.toNumber(row?.protein),
      fat: this.toNumber(row?.fat),
      fiber: this.toNumber(row?.fiber),
      sodiumMg: this.toNumber(row?.sodium_mg),
      calciumMg: this.toNumber(row?.calcium_mg),
      ironMg: this.toNumber(row?.iron_mg),
      vitaminAMcg: this.toNumber(row?.vitamin_a_mcg),
      vitaminCMg: this.toNumber(row?.vitamin_c_mg),
      vitaminDIU: this.toNumber(row?.vitamin_d_iu),
    };
  }

  async getDailyBurnedCalories(userId: string, date: string): Promise<number> {
    const result = await this.pool.query<ExerciseAggregateRow>(
      `SELECT COALESCE(SUM(calories_burned), 0) AS burned_calories
       FROM exercise_records
       WHERE user_id = $1 AND recorded_on = $2`,
      [userId, date],
    );

    return this.toNumber(result.rows[0]?.burned_calories);
  }

  async findDietRecordsByUserIdAndDateRange(
    userId: string,
    from: string,
    to: string,
    limit: number,
  ): Promise<DietRecordHistoryItem[]> {
    const result = await this.pool.query<DietHistoryRow>(
      `SELECT
         meal_type,
         food_name,
         recorded_on,
         calories,
         carbs,
         protein,
         fat,
         fiber,
         sodium_mg,
         calcium_mg,
         iron_mg,
         vitamin_a_mcg,
         vitamin_c_mg,
         vitamin_d_iu
       FROM diet_records
       WHERE user_id = $1 AND recorded_on BETWEEN $2 AND $3
       ORDER BY recorded_on DESC, id DESC
       LIMIT $4`,
      [userId, from, to, limit],
    );

    return result.rows.map((row) => ({
      mealType: row.meal_type,
      foodName: row.food_name,
      nutrition: this.mapNutrition(row),
      recordedOn: row.recorded_on,
    }));
  }

  async findExerciseRecordsByUserIdAndDateRange(
    userId: string,
    from: string,
    to: string,
    limit: number,
  ): Promise<ExerciseRecordHistoryItem[]> {
    const result = await this.pool.query<ExerciseHistoryRow>(
      `SELECT
         exercise_type,
         duration_minutes,
         calories_burned,
         recorded_on
       FROM exercise_records
       WHERE user_id = $1 AND recorded_on BETWEEN $2 AND $3
       ORDER BY recorded_on DESC, id DESC
       LIMIT $4`,
      [userId, from, to, limit],
    );

    return result.rows.map((row) => ({
      exerciseType: row.exercise_type,
      durationMinutes: row.duration_minutes,
      caloriesBurned: this.toNumber(row.calories_burned),
      recordedOn: row.recorded_on,
    }));
  }

  private mapProfile(row: ProfileRow): CreateProfileDto {
    return {
      id: row.user_id,
      nickname: row.nickname,
      age: row.age,
      gender: row.gender,
      heightCm: this.toNumber(row.height_cm),
      weightKg: this.toNumber(row.weight_kg),
      goal: row.goal,
    };
  }

  private mapNutrition(row: DietAggregateRow): NutritionMetrics {
    return {
      calories: this.toNumber(row.calories),
      carbs: this.toNumber(row.carbs),
      protein: this.toNumber(row.protein),
      fat: this.toNumber(row.fat),
      fiber: this.toNumber(row.fiber),
      sodiumMg: this.toNumber(row.sodium_mg),
      calciumMg: this.toNumber(row.calcium_mg),
      ironMg: this.toNumber(row.iron_mg),
      vitaminAMcg: this.toNumber(row.vitamin_a_mcg),
      vitaminCMg: this.toNumber(row.vitamin_c_mg),
      vitaminDIU: this.toNumber(row.vitamin_d_iu),
    };
  }

  private toNumber(value: number | string | undefined): number {
    if (value === undefined) {
      return 0;
    }

    return Number(value);
  }
}
