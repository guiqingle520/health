import { IsIn, IsOptional } from 'class-validator';
import { GetRecordHistoryQueryDto } from './get-record-history-query.dto';

export class GetExerciseRecordHistoryQueryDto extends GetRecordHistoryQueryDto {
  @IsOptional()
  @IsIn(['aerobic', 'strength', 'flexibility'])
  exerciseType?: 'aerobic' | 'strength' | 'flexibility';
}
