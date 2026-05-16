import { ConfigService } from '@nestjs/config';

export function getJwtSecret(
  configService: ConfigService,
  key: 'JWT_ACCESS_SECRET' | 'JWT_REFRESH_SECRET',
  fallback: string,
): string {
  const configured = configService.get<string>(key);
  if (typeof configured === 'string' && configured.trim().length > 0) {
    return configured;
  }

  return fallback;
}
