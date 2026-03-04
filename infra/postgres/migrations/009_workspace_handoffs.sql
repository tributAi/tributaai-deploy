-- migration: 009_workspace_handoffs.sql
-- Create handoffs and workspace cases tables for the Workspace POC

CREATE TYPE handoff_status AS ENUM ('PENDING', 'IMPORTED', 'REVOKED', 'EXPIRED');

CREATE TABLE handoffs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(16) UNIQUE NOT NULL,
    case_id UUID NOT NULL,
    payload_json JSONB NOT NULL,
    status handoff_status NOT NULL DEFAULT 'PENDING',
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookup by code when status is PENDING (helps avoid brute force / seq scans)
CREATE INDEX idx_handoffs_code_pending ON handoffs(code) WHERE status = 'PENDING';
-- Index for case_id to allow easy revocation by user who created the case
CREATE INDEX idx_handoffs_case_id ON handoffs(case_id);

CREATE TABLE workspace_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    handoff_id UUID NOT NULL REFERENCES handoffs(id),
    snapshot JSONB NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    notes TEXT,
    imported_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index to quickly find cases by professional/tenant
CREATE INDEX idx_workspace_cases_tenant ON workspace_cases(tenant_id);
