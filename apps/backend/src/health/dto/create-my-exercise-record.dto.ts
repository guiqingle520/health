import { IsIn, IsInt, IsNumber, Min } from 'class-validator';

export class CreateMyExerciseRecordDto {
  @IsIn(['aerobic', 'strength', 'flexibility'])
  exerciseType!: 'aerobic' | 'strength' | 'flexibility';

  @IsInt()
  @Min(1)
  durationMinutes!: number;

  @IsNumber()
  @Min(0)
  caloriesBurned!: number;
}
