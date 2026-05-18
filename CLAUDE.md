# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository shape

This is a health-management monorepo with three active areas:
- `apps/backend`: NestJS API backed by PostgreSQL.
- `apps/mobile`: Flutter client for Android/iOS/Web.
- `packages/shared`: small shared TypeScript types package (`@health/shared`).
- `docs`: product, architecture, API, database, UI, QA, and setup docs. Start with `docs/README.md` for the curated reading order.

The root npm workspace includes `apps/backend` and `packages/shared`. The Flutter app is not part of the npm workspace and is managed separately with Flutter tooling.

## Common commands

### Root workspace
- `npm install`
- `npm run backend:build`
- `npm run backend:lint`
- `npm run backend:test`

### Backend (`apps/backend`)
- `npm install`
- `npm run start:dev`
- `npm run build`
- `npm run start:prod`
- `npm run lint`
- `npm run test`
- `npm run test:e2e`
- Single test file: `npx jest test/app.e2e-spec.ts --config ./test/jest-e2e.json`
- Single unit test pattern: `npx jest src/<path>/<file>.spec.ts`

### Mobile (`apps/mobile`)
- `flutter pub get`
- `flutter run -d chrome`
- `flutter devices`
- `flutter run -d <deviceId>`
- `flutter analyze`
- `flutter build apk --release`
- `flutter build appbundle --release`

## Environment and runtime

Backend configuration is loaded with `ConfigModule` in `apps/backend/src/app.module.ts`.
- Test runs load `.env.test` first, then `.env`.
- Non-test runs load `.env`.
- The backend listens on `process.env.PORT ?? 3000` in `apps/backend/src/main.ts`.

The backend now depends on PostgreSQL for auth, profiles, diet/exercise records, history, summaries, and dashboard aggregation. E2E tests are integration-style and expect a reachable PostgreSQL instance matching `.env.test`.

For Android emulator runs, the Flutter client defaults `API_BASE_URL` to `http://10.0.2.2:3000`. Override with `--dart-define=API_BASE_URL=...` when the backend is on another port.

## Architecture overview

### Backend

The NestJS app is intentionally thin and follows a consistent flow:
- controllers define REST endpoints and auth boundaries,
- services contain lightweight orchestration and small business rules,
- repositories perform raw SQL queries through `pg`.

Key modules:
- `AuthModule`: phone-code login, current-user lookup, refresh-token flow.
- `HealthModule`: profile CRUD, diet/exercise writes, history reads, daily summary, dashboard.
- `DatabaseModule`: global PostgreSQL pool provider and shutdown cleanup.

Important implementation pattern:
- API fields are camelCase.
- PostgreSQL columns are snake_case.
- Repository methods do the mapping between them.
- Numeric SQL values are normalized back to numbers in repository code before returning upstream.

Current auth/data boundaries matter:
- “current user” resources should use JWT `sub`, not trust caller-supplied `userId`.
- New protected health endpoints should follow the same guard pattern as `/health/profiles/me` and `/health/dashboard/today`.
- Public write endpoints still exist for some record creation flows; docs indicate the direction is to bind all health writes to the authenticated user over time.

### Mobile

The Flutter app is currently a single-file flow in `apps/mobile/lib/main.dart`.
- `AppStage` drives the app through `login -> onboarding -> dashboard`.
- `ApiClient` is the integration seam for backend requests.
- There is not yet a larger page/module split, so backend API additions often require matching request/response additions in this file.

Current startup flow:
1. login via `/auth/login`
2. fetch current profile via `/health/profiles/me`
3. if missing, go to onboarding and submit `/health/profiles/me`
4. otherwise load `/health/dashboard/today`

### Shared package

`packages/shared` currently holds a small set of domain types (`UserProfile`, nutrition-related types). It is lightweight and not a comprehensive contract layer yet.

## Data model and domain context

The current PostgreSQL schema lives in `apps/backend/sql/m1_m2_schema.sql` and includes:
- `users`
- `user_profiles`
- `auth_refresh_tokens`
- `diet_records`
- `exercise_records`

The implemented MVP focus is personal health management: profile, diet, exercise, history, daily summary, and dashboard. Per the docs, “companion context” is an explanatory layer for user health behavior, not a separate pet-health product domain.

## Key docs to trust

When you need product or architecture context, prefer these docs:
- `docs/README.md`: document index and current repo status.
- `docs/00-overview/architecture.md`: system boundaries, module layering, roadmap.
- `docs/03-technical/development-plan.md`: current baseline, iteration priorities, backend/mobile design constraints.
- `docs/setup.md`: local environment and run commands.

Important guidance pulled from docs:
- Current user health data should ultimately be bound to the authenticated user.
- API should stay camelCase while DB remains snake_case.
- Companion context is part of user-health interpretation, not a standalone pet module.

## Testing notes

Backend e2e coverage currently centers on the integrated health flow in `apps/backend/test/app.e2e-spec.ts`: login, profile, diet/exercise writes, history, daily summary, and dashboard. If these tests fail unexpectedly, verify database reachability before assuming the app logic is broken.

When changing backend APIs that the mobile app consumes, run both:
- backend build/e2e checks
- `flutter analyze` in `apps/mobile`
