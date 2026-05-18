import { Global, Inject, Module, OnApplicationShutdown } from '@nestjs/common';
import type { Pool } from 'pg';
import { DATABASE_POOL } from './database.constants';
import { databaseProviders } from './database.providers';

@Global()
@Module({
  providers: [...databaseProviders],
  exports: [...databaseProviders],
})
export class DatabaseModule implements OnApplicationShutdown {
  private isClosed = false;

  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  async onApplicationShutdown(): Promise<void> {
    if (this.isClosed) {
      return;
    }

    this.isClosed = true;
    await this.pool.end();
  }
}
