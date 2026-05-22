import { Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Pool, PoolConfig } from 'pg';
import { DATABASE_POOL } from './database.constants';

export const databaseProviders: Provider[] = [
  {
    provide: DATABASE_POOL,
    inject: [ConfigService],
    useFactory: (configService: ConfigService) => {
      const host = configService.get<string>('DB_HOST');
      const database = configService.get<string>('DB_NAME');
      const user = configService.get<string>('DB_USER');
      const password = configService.get<string>('DB_PASSWORD');

      if (!host || !database || !user || !password) {
        throw new Error(
          'Database configuration is incomplete. Expected DB_HOST, DB_NAME, DB_USER, and DB_PASSWORD.',
        );
      }

      const ssl = configService.get<string>('DB_SSL');
      const poolConfig: PoolConfig = {
        host,
        port: Number(configService.get<string>('DB_PORT') ?? '5432'),
        database,
        user,
        password,
        max: Number(configService.get<string>('DB_MAX_CONNECTIONS') ?? '10'),
      };

      if (ssl === 'true') {
        poolConfig.ssl = { rejectUnauthorized: false };
      }

      return new Pool(poolConfig);
    },
  },
];
