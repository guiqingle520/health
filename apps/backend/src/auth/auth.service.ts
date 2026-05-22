import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import { LoginDto } from './dto/login.dto';
import {
  AuthTokenPayload,
  AuthTokens,
  AuthUser,
  LoginResponse,
} from './interfaces/auth.types';
import { getJwtSecret } from './jwt-secret.util';
import { AuthRepository } from './auth.repository';

@Injectable()
export class AuthService {
  constructor(
    @Inject(JwtService) private readonly jwtService: JwtService,
    @Inject(ConfigService) private readonly configService: ConfigService,
    @Inject(AuthRepository) private readonly authRepository: AuthRepository,
  ) {}

  async login(payload: LoginDto): Promise<LoginResponse> {
    const user = await this.findOrCreateUser(payload.phone);
    const tokens = await this.issueTokens(user);
    await this.authRepository.upsertRefreshToken(user.id, tokens.refreshToken);
    return { user, ...tokens };
  }

  async refresh(
    userId: string,
    refreshToken: string,
  ): Promise<{ user: AuthUser } & AuthTokens> {
    const savedToken = await this.authRepository.findRefreshTokenByUserId(userId);
    if (!savedToken || savedToken !== refreshToken) {
      throw new UnauthorizedException('invalid refresh token');
    }

    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new UnauthorizedException('user not found');
    }

    const tokens = await this.issueTokens(user);
    await this.authRepository.upsertRefreshToken(user.id, tokens.refreshToken);
    return { user, ...tokens };
  }

  async getUser(userId: string): Promise<AuthUser> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new UnauthorizedException('user not found');
    }
    return user;
  }

  private async findOrCreateUser(phone: string): Promise<AuthUser> {
    const existingUser = await this.authRepository.findUserByPhone(phone);
    if (existingUser) {
      return existingUser;
    }

    return this.authRepository.createUser({
      id: randomUUID(),
      phone,
    });
  }

  private async issueTokens(user: AuthUser): Promise<AuthTokens> {
    const payload: AuthTokenPayload = {
      sub: user.id,
      phone: user.phone,
    };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: getJwtSecret(
          this.configService,
          'JWT_ACCESS_SECRET',
          'dev-access-secret',
        ),
        expiresIn: '2h',
      }),
      this.jwtService.signAsync(payload, {
        secret: getJwtSecret(
          this.configService,
          'JWT_REFRESH_SECRET',
          'dev-refresh-secret',
        ),
        expiresIn: '30d',
      }),
    ]);

    return { accessToken, refreshToken };
  }
}
