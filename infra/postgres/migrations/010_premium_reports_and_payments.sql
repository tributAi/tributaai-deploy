-- Migration 010: Premium reports and payments
-- Extends reports for free/premium, adds payments table

ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS type VARCHAR(20) DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS plan VARCHAR(50) NULL,
  ADD COLUMN IF NOT EXISTS content_json JSONB NULL,
  ADD COLUMN IF NOT EXISTS pdf_url TEXT NULL,
  ADD COLUMN IF NOT EXISTS user_id VARCHAR(255) NULL;

UPDATE reports r
SET user_id = c.user_id
FROM cases c
WHERE r.case_id = c.id AND r.user_id IS NULL;

UPDATE reports SET user_id = 'user-1' WHERE user_id IS NULL;

ALTER TABLE reports ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE reports ALTER COLUMN user_id SET DEFAULT 'user-1';

ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_status_check;
ALTER TABLE reports ADD CONSTRAINT reports_status_check CHECK (
  status IN ('pending', 'generating', 'completed', 'failed', 'locked', 'unlocked', 'generating_pdf', 'ready')
);
ALTER TABLE reports ADD CONSTRAINT reports_type_check CHECK (type IN ('free', 'premium'));
ALTER TABLE reports ADD CONSTRAINT reports_plan_check CHECK (
  plan IS NULL OR plan IN ('premium_basic', 'premium_plus')
);

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  user_id VARCHAR(255) NOT NULL,
  provider VARCHAR(50) NOT NULL DEFAULT 'stripe',
  provider_payment_id VARCHAR(255),
  status VARCHAR(30) NOT NULL CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
  amount DECIMAL(12, 2) NOT NULL,
  currency VARCHAR(3) NOT NULL DEFAULT 'EUR',
  plan VARCHAR(50),
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reports_case_id_type ON reports(case_id, type);
CREATE INDEX IF NOT EXISTS idx_payments_case_id ON payments(case_id);
CREATE INDEX IF NOT EXISTS idx_payments_provider_payment_id ON payments(provider_payment_id);
