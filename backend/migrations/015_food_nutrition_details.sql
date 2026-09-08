ALTER TABLE foods ADD COLUMN saturated_fat_g double precision NOT NULL DEFAULT 0 CHECK (saturated_fat_g >= 0);
ALTER TABLE foods ADD COLUMN trans_fat_g double precision NOT NULL DEFAULT 0 CHECK (trans_fat_g >= 0);
ALTER TABLE foods ADD COLUMN monounsaturated_fat_g double precision NOT NULL DEFAULT 0 CHECK (monounsaturated_fat_g >= 0);
ALTER TABLE foods ADD COLUMN polyunsaturated_fat_g double precision NOT NULL DEFAULT 0 CHECK (polyunsaturated_fat_g >= 0);
ALTER TABLE foods ADD COLUMN sugar_g double precision NOT NULL DEFAULT 0 CHECK (sugar_g >= 0);
ALTER TABLE foods ADD COLUMN added_sugar_g double precision NOT NULL DEFAULT 0 CHECK (added_sugar_g >= 0);
ALTER TABLE foods ADD COLUMN sodium_mg double precision NOT NULL DEFAULT 0 CHECK (sodium_mg >= 0);
ALTER TABLE foods ADD COLUMN cholesterol_mg double precision NOT NULL DEFAULT 0 CHECK (cholesterol_mg >= 0);
