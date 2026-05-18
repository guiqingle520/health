import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { HealthModule } from './health/health.module';

const isTestEnvironment = process.env.NODE_ENV === 'test' || !!process.env.JEST_WORKER_ID;

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: isTestEnvironment ? ['.env.test', '.env'] : ['.env'],
    }),
    DatabaseModule,
    AuthModule,
    HealthModule,
  ],
})
export class AppModule {}
