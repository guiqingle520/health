import { IsIn, IsInt, IsNumber, IsString, Min } from 'class-validator';

export class CreateExerciseRecordDto {
  @IsString()
  userId!: string;

  @IsIn(['aerobic', 'strength', 'flexibility'])
  exerciseType!: 'aerobic' | 'strength' | 'flexibility';

  @IsInt()
  @Min(1)
  durationMinutes!: number;

  @IsNumber()
  @Min(0)
  caloriesBurned!: number;
}
