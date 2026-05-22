export type Gender = 'male' | 'female';
export type HealthGoal = 'lose_fat' | 'gain_muscle' | 'maintain';

export interface UserProfile {
  id: string;
  nickname: string;
  age: number;
  gender: Gender;
  heightCm: number;
  weightKg: number;
  goal: HealthGoal;
}

export interface Nutrition {
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
  fiber: number;
  sodiumMg: number;
  calciumMg: number;
  ironMg: number;
  vitaminAMcg: number;
  vitaminCMg: number;
  vitaminDIU: number;
}
