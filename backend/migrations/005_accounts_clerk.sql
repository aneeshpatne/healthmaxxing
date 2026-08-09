ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS clerk_user_id text UNIQUE,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_accounts_clerk_user_id
  ON accounts(clerk_user_id);
