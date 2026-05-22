import { IsIn, IsInt, IsNumber, IsString, Max, Min } from 'class-validator';

export class UpsertMyProfileDto {
  @IsString()
  nickname!: string;

  @IsInt()
  @Min(1)
  @Max(120)
  age!: number;

  @IsIn(['male', 'female'])
  gender!: 'male' | 'female';

  @IsNumber()
  @Min(100)
  @Max(250)
  heightCm!: number;

  @IsNumber()
  @Min(20)
  @Max(300)
  weightKg!: number;

  @IsIn(['lose_fat', 'gain_muscle', 'maintain'])
  goal!: 'lose_fat' | 'gain_muscle' | 'maintain';
}
