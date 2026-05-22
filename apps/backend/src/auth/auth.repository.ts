import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { DATABASE_POOL } from '../database/database.constants';
import type { AuthUser } from './interfaces/auth.types';

@Injectable()
export class AuthRepository {
  constructor(@Inject(DATABASE_POOL) private readonly pool: Pool) {}

  async findUserByPhone(phone: string): Promise<AuthUser | undefined> {
    const result = await this.pool.query<{ id: string; phone: string }>(
      'SELECT id, phone FROM users WHERE phone = $1',
      [phone],
    );

    return result.rows[0];
  }

  async createUser(user: AuthUser): Promise<AuthUser> {
    const result = await this.pool.query<{ id: string; phone: string }>(
      'INSERT INTO users (id, phone) VALUES ($1, $2) RETURNING id, phone',
      [user.id, user.phone],
    );

    return result.rows[0];
  }

  async findUserById(userId: string): Promise<AuthUser | undefined> {
    const result = await this.pool.query<{ id: string; phone: string }>(
      'SELECT id, phone FROM users WHERE id = $1',
      [userId],
    );

    return result.rows[0];
  }

  async upsertRefreshToken(userId: string, refreshToken: string): Promise<void> {
    await this.pool.query(
      `INSERT INTO auth_refresh_tokens (user_id, refresh_token)
       VALUES ($1, $2)
       ON CONFLICT (user_id)
       DO UPDATE SET refresh_token = EXCLUDED.refresh_token, updated_at = NOW()`,
      [userId, refreshToken],
    );
  }

  async findRefreshTokenByUserId(userId: string): Promise<string | undefined> {
    const result = await this.pool.query<{ refresh_token: string }>(
      'SELECT refresh_token FROM auth_refresh_tokens WHERE user_id = $1',
      [userId],
    );

    return result.rows[0]?.refresh_token;
  }
}
