import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthTokenPayload } from './interfaces/auth.types';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthTokenPayload => {
    const request = ctx.switchToHttp().getRequest<{ user: AuthTokenPayload }>();
    return request.user;
  },
);
