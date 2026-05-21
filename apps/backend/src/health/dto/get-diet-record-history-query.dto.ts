import { IsIn, IsOptional } from 'class-validator';
import { GetRecordHistoryQueryDto } from './get-record-history-query.dto';

export class GetDietRecordHistoryQueryDto extends GetRecordHistoryQueryDto {
  @IsOptional()
  @IsIn(['breakfast', 'lunch', 'dinner', 'snack'])
  mealType?: 'breakfast' | 'lunch' | 'dinner' | 'snack';
}
