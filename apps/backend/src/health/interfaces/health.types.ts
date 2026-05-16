export interface NutritionMetrics {
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

export interface DailySummary {
  date: string;
  intake: NutritionMetrics;
  burnedCalories: number;
  suggestion: string;
}

export interface DashboardCardMetrics {
  steps: number;
  stepTarget: number;
  sleepHours: number;
  sleepScore: number;
  waterMl: number;
  waterTargetMl: number;
  calories: number;
  calorieTarget: number;
}

export interface DashboardView {
  date: string;
  healthScore: number;
  profile: {
    nickname: string;
    goal: 'lose_fat' | 'gain_muscle' | 'maintain';
  } | null;
  cards: DashboardCardMetrics;
  aiInsights: string[];
  summary: DailySummary;
}
