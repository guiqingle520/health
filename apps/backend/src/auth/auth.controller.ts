import { Body, Controller, Get, Inject, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from './current-user.decorator';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthService } from './auth.service';
import type { AuthTokenPayload } from './interfaces/auth.types';

@Controller('auth')
export class AuthController {
  constructor(@Inject(AuthService) private readonly authService: AuthService) {}

  @Post('login')
  login(@Body() payload: LoginDto) {
    return this.authService.login(payload);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@CurrentUser() user: AuthTokenPayload) {
    return this.authService.getUser(user.sub);
  }

  @UseGuards(JwtAuthGuard)
  @Post('refresh')
  refresh(
    @CurrentUser() user: AuthTokenPayload,
    @Body() payload: RefreshTokenDto,
  ) {
    return this.authService.refresh(user.sub, payload.refreshToken);
  }
}
