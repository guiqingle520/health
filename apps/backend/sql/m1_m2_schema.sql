CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  phone VARCHAR(20) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  nickname VARCHAR(50) NOT NULL,
  age INT NOT NULL CHECK (age >= 1 AND age <= 120),
  gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female')),
  height_cm NUMERIC(5, 2) NOT NULL CHECK (height_cm >= 100 AND height_cm <= 250),
  weight_kg NUMERIC(5, 2) NOT NULL CHECK (weight_kg >= 20 AND weight_kg <= 300),
  goal VARCHAR(20) NOT NULL CHECK (goal IN ('lose_fat', 'gain_muscle', 'maintain')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auth_refresh_tokens (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  refresh_token TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercise_records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_type VARCHAR(50) NOT NULL,
  duration_minutes INT NOT NULL CHECK (duration_minutes > 0),
  calories_burned NUMERIC(8, 2) NOT NULL DEFAULT 0,
  recorded_on DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_diet_records_user_date
  ON diet_records (user_id, recorded_on);

CREATE INDEX IF NOT EXISTS idx_exercise_records_user_date
  ON exercise_records (user_id, recorded_on);
