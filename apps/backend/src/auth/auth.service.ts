import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import {
  AuthTokenPayload,
  AuthUser,
  AuthTokens,
  LoginResponse,
} from './interfaces/auth.types';
import { LoginDto } from './dto/login.dto';
import { getJwtSecret } from './jwt-secret.util';

@Injectable()
export class AuthService {
  private readonly usersByPhone = new Map<string, AuthUser>();
  private readonly usersById = new Map<string, AuthUser>();
  private readonly refreshTokensByUserId = new Map<string, string>();

  constructor(
    @Inject(JwtService) private readonly jwtService: JwtService,
    @Inject(ConfigService) private readonly configService: ConfigService,
  ) {}

  async login(payload: LoginDto): Promise<LoginResponse> {
    const user = this.findOrCreateUser(payload.phone);
    const tokens = await this.issueTokens(user);
    this.refreshTokensByUserId.set(user.id, tokens.refreshToken);
    return { user, ...tokens };
  }

  async refresh(
    userId: string,
    refreshToken: string,
  ): Promise<{ user: AuthUser } & AuthTokens> {
    const savedToken = this.refreshTokensByUserId.get(userId);
    if (!savedToken || savedToken !== refreshToken) {
      throw new UnauthorizedException('invalid refresh token');
    }

    const user = this.usersById.get(userId);
    if (!user) {
      throw new UnauthorizedException('user not found');
    }

    const tokens = await this.issueTokens(user);
    this.refreshTokensByUserId.set(user.id, tokens.refreshToken);
    return { user, ...tokens };
  }

  getUser(userId: string): AuthUser {
    const user = this.usersById.get(userId);
    if (!user) {
      throw new UnauthorizedException('user not found');
    }
    return user;
  }

  private findOrCreateUser(phone: string): AuthUser {
    const existingUser = this.usersByPhone.get(phone);
    if (existingUser) {
      return existingUser;
    }

    const user: AuthUser = {
      id: randomUUID(),
      phone,
    };
    this.usersByPhone.set(phone, user);
    this.usersById.set(user.id, user);
    return user;
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
