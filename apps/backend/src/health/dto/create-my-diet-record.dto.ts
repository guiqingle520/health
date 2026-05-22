import { Type } from 'class-transformer';
import {
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { NutritionMetrics } from '../interfaces/health.types';

class NutritionMetricsDto implements NutritionMetrics {
  @IsNumber()
  @Min(0)
  calories!: number;

  @IsNumber()
  @Min(0)
  carbs!: number;

  @IsNumber()
  @Min(0)
  protein!: number;

  @IsNumber()
  @Min(0)
  fat!: number;

  @IsNumber()
  @Min(0)
  fiber!: number;

  @IsNumber()
  @Min(0)
  sodiumMg!: number;

  @IsNumber()
  @Min(0)
  calciumMg!: number;

  @IsNumber()
  @Min(0)
  ironMg!: number;

  @IsNumber()
  @Min(0)
  vitaminAMcg!: number;

  @IsNumber()
  @Min(0)
  vitaminCMg!: number;

  @IsNumber()
  @Min(0)
  vitaminDIU!: number;
}

export class CreateMyDietRecordDto {
  @IsIn(['breakfast', 'lunch', 'dinner', 'snack'])
  mealType!: 'breakfast' | 'lunch' | 'dinner' | 'snack';

  @IsString()
  @IsNotEmpty()
  foodName!: string;

  @IsObject()
  @ValidateNested()
  @Type(() => NutritionMetricsDto)
  nutrition!: NutritionMetricsDto;
}
