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
