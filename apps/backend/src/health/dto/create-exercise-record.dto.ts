export class CreateExerciseRecordDto {
  userId!: string;
  exerciseType!: 'aerobic' | 'strength' | 'flexibility';
  durationMinutes!: number;
  caloriesBurned!: number;
}
