ALTER TABLE measurements ADD COLUMN IF NOT EXISTS idempotency_key text;

CREATE UNIQUE INDEX idx_measurements_profile_idempotency
  ON measurements(profile_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
