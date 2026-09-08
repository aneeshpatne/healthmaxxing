CREATE TABLE foods (
  id uuid PRIMARY KEY,
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  serving_description text NOT NULL,
  calories double precision NOT NULL CHECK (calories >= 0),
  protein_g double precision NOT NULL CHECK (protein_g >= 0),
  carbs_g double precision NOT NULL CHECK (carbs_g >= 0),
  fat_g double precision NOT NULL CHECK (fat_g >= 0),
  fiber_g double precision NOT NULL DEFAULT 0 CHECK (fiber_g >= 0),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE food_entries (
  id uuid PRIMARY KEY,
  profile_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  food_id uuid NOT NULL REFERENCES foods(id) ON DELETE RESTRICT,
  servings double precision NOT NULL DEFAULT 1 CHECK (servings > 0),
  meal text NOT NULL DEFAULT 'snack' CHECK (meal IN ('breakfast', 'lunch', 'dinner', 'snack')),
  logged_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_foods_profile_name ON foods(profile_id, lower(name));
CREATE INDEX idx_food_entries_profile_logged ON food_entries(profile_id, logged_at DESC);
