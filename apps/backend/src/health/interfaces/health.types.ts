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

export interface DietRecordHistoryItem {
  id: string;
  mealType: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  foodName: string;
  nutrition: NutritionMetrics;
  recordedOn: string;
}

export interface ExerciseRecordHistoryItem {
  id: string;
  exerciseType: 'aerobic' | 'strength' | 'flexibility';
  durationMinutes: number;
  caloriesBurned: number;
  recordedOn: string;
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

export type HealthTrendMetric =
  | 'weight'
  | 'score'
  | 'heartRate'
  | 'calories'
  | 'water'
  | 'sleep';

export type HealthTrendPeriod = 'week' | 'month' | 'year';

export interface HealthTrendPoint {
  date: string;
  value: number;
}

export interface HealthTrendSignal {
  level: 'info' | 'warning';
  message: string;
}

export interface HealthTrendView {
  metric: HealthTrendMetric;
  period: HealthTrendPeriod;
  currentValue: number;
  delta: number;
  unit: string;
  points: HealthTrendPoint[];
  signals: HealthTrendSignal[];
}

export interface AiRecommendationItem {
  id: string;
  type: 'diet' | 'exercise' | 'water' | 'sleep';
  title: string;
  reason: string;
  actionText: string;
  status: 'pending';
}

export interface AiRecommendationTodayView {
  date: string;
  items: AiRecommendationItem[];
}

export interface ProfileCenterView {
  profile: {
    nickname: string;
    goal: 'lose_fat' | 'gain_muscle' | 'maintain';
    goalLabel: string;
  };
  stats: {
    healthScore: number;
    streakDays: number;
    reportCount: number;
    connectedDevices: number;
  };
  pro: {
    enabled: boolean;
    title: string;
    subtitle: string;
  };
  sections: Array<{
    id: string;
    title: string;
    subtitle: string;
  }>;
}
