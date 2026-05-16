import { IsNotEmpty, Matches } from 'class-validator';

export class LoginDto {
  @Matches(/^\d{11}$/, { message: 'phone must be an 11-digit number' })
  phone!: string;

  @IsNotEmpty()
  @Matches(/^\d{4,6}$/, { message: 'code must be a 4-6 digit number' })
  code!: string;
}
