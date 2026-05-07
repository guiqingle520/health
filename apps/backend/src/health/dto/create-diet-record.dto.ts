import { NutritionMetrics } from '../interfaces/health.types';

export class CreateDietRecordDto {
  userId!: string;
  mealType!: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  foodName!: string;
  nutrition!: NutritionMetrics;
}
