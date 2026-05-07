export class CreateProfileDto {
  id!: string;
  nickname!: string;
  age!: number;
  gender!: 'male' | 'female';
  heightCm!: number;
  weightKg!: number;
  goal!: 'lose_fat' | 'gain_muscle' | 'maintain';
}
