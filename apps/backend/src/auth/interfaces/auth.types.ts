export interface AuthUser {
  id: string;
  phone: string;
}

export interface AuthTokenPayload {
  sub: string;
  phone: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface LoginResponse extends AuthTokens {
  user: AuthUser;
}
