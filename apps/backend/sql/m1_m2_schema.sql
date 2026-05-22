CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  phone VARCHAR(20) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  nickname VARCHAR(50) NOT NULL,
  age INT NOT NULL CHECK (age >= 1 AND age <= 120),
  gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female')),
  height_cm NUMERIC(5, 2) NOT NULL CHECK (height_cm >= 100 AND height_cm <= 250),
  weight_kg NUMERIC(5, 2) NOT NULL CHECK (weight_kg >= 20 AND weight_kg <= 300),
  goal VARCHAR(20) NOT NULL CHECK (goal IN ('lose_fat', 'gain_muscle', 'maintain')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  refresh_token TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS diet_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  meal_type VARCHAR(20) NOT NULL,
  food_name VARCHAR(100) NOT NULL,
  recorded_on DATE NOT NULL,
  calories NUMERIC(8, 2) NOT NULL DEFAULT 0,
  carbs NUMERIC(8, 2) NOT NULL DEFAULT 0,
  protein NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fat NUMERIC(8, 2) NOT NULL DEFAULT 0,
  fiber NUMERIC(8, 2) NOT NULL DEFAULT 0,
  sodium_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  calcium_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  iron_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  vitamin_a_mcg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  vitamin_c_mg NUMERIC(8, 2) NOT NULL DEFAULT 0,
  vitamin_d_iu NUMERIC(8, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercise_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_type VARCHAR(50) NOT NULL,
  duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
  calories_burned NUMERIC(8, 2) NOT NULL DEFAULT 0,
  recorded_on DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS water_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_ml NUMERIC(8, 2) NOT NULL CHECK (amount_ml > 0),
  recorded_at TIMESTAMPTZ NOT NULL,
  source VARCHAR(20) NOT NULL DEFAULT 'manual',
  note VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sleep_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sleep_start TIMESTAMPTZ NOT NULL,
  sleep_end TIMESTAMPTZ NOT NULL,
  duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
  sleep_score NUMERIC(5, 2),
  source VARCHAR(20) NOT NULL DEFAULT 'manual',
  note VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  water_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  exercise_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sleep_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  weekly_report_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  goal_reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours_start VARCHAR(5),
  quiet_hours_end VARCHAR(5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_goals (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_type VARCHAR(30) NOT NULL CHECK (
    goal_type IN ('water', 'exercise_minutes', 'sleep_hours', 'steps', 'calories', 'weight')
  ),
  target_value NUMERIC(10, 2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  period VARCHAR(20) NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly')),
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'archived')),
  source VARCHAR(20) NOT NULL DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_metric_events (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metric_type VARCHAR(50) NOT NULL,
  value NUMERIC(12, 2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL,
  source VARCHAR(20) NOT NULL DEFAULT 'manual',
  source_record_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_recommendations (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL,
  title VARCHAR(120) NOT NULL,
  reason TEXT NOT NULL,
  action_text VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'dismissed', 'snoozed')),
  generated_on DATE NOT NULL,
  source_metric_type VARCHAR(50),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_reports (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('week', 'month', 'quarter', 'year')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb,
  file_url TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'generated', 'shared', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS report_shares (
  id UUID PRIMARY KEY,
  report_id UUID NOT NULL REFERENCES health_reports(id) ON DELETE CASCADE,
  owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shared_with_type VARCHAR(20) NOT NULL CHECK (shared_with_type IN ('link', 'family', 'doctor')),
  shared_with_value TEXT,
  permission VARCHAR(20) NOT NULL DEFAULT 'view' CHECK (permission IN ('view', 'comment')),
  share_token TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diet_records_user_date
  ON diet_records (user_id, recorded_on);

CREATE INDEX IF NOT EXISTS idx_exercise_records_user_date
  ON exercise_records (user_id, recorded_on);

CREATE INDEX IF NOT EXISTS idx_water_records_user_recorded_at
  ON water_records (user_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_sleep_records_user_recorded_at
  ON sleep_records (user_id, sleep_start DESC);

CREATE INDEX IF NOT EXISTS idx_health_goals_user_status
  ON health_goals (user_id, status, goal_type);

CREATE INDEX IF NOT EXISTS idx_health_metric_events_user_metric_time
  ON health_metric_events (user_id, metric_type, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user_date
  ON ai_recommendations (user_id, generated_on DESC);

CREATE INDEX IF NOT EXISTS idx_health_reports_user_period
  ON health_reports (user_id, period_type, period_start DESC);
