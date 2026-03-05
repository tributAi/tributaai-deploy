CREATE TABLE IF NOT EXISTS sophia_accounts (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                  VARCHAR(255) UNIQUE NOT NULL,
  password_hash          VARCHAR(255),
  name                   VARCHAR(255),
  oab_number             VARCHAR(50),
  phone                  VARCHAR(50),
  avatar_url             TEXT,
  plan                   VARCHAR(20)  NOT NULL DEFAULT 'TRIAL',
  auth_provider          VARCHAR(20)  NOT NULL DEFAULT 'email',
  external_id            VARCHAR(255),
  stripe_customer_id     VARCHAR(255),
  stripe_subscription_id VARCHAR(255),
  subscription_status    VARCHAR(30)  DEFAULT 'trialing',
  trial_ends_at          TIMESTAMPTZ,
  created_at             TIMESTAMPTZ  DEFAULT NOW(),
  updated_at             TIMESTAMPTZ  DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sophia_accounts_email
  ON sophia_accounts(email);

CREATE INDEX IF NOT EXISTS idx_sophia_accounts_external
  ON sophia_accounts(auth_provider, external_id)
  WHERE external_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sophia_accounts_stripe
  ON sophia_accounts(stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;
