-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Rules table with JSONB
CREATE TABLE IF NOT EXISTS rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country VARCHAR(2) NOT NULL,
    version INTEGER NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    rule_data JSONB NOT NULL,
    source_reference TEXT,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(country, version)
);

CREATE INDEX idx_rules_country ON rules(country);
CREATE INDEX idx_rules_status ON rules(status);
CREATE INDEX idx_rules_effective ON rules(effective_from, effective_to);
CREATE INDEX idx_rules_data ON rules USING GIN(rule_data);

-- Treaties table with JSONB
CREATE TABLE IF NOT EXISTS treaties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country_pair VARCHAR(10) NOT NULL,
    version INTEGER NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    treaty_data JSONB NOT NULL,
    source_reference TEXT,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(country_pair, version)
);

CREATE INDEX idx_treaties_pair ON treaties(country_pair);
CREATE INDEX idx_treaties_status ON treaties(status);
CREATE INDEX idx_treaties_effective ON treaties(effective_from, effective_to);
CREATE INDEX idx_treaties_data ON treaties USING GIN(treaty_data);

-- Tax tables with JSONB
CREATE TABLE IF NOT EXISTS tax_tables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    country VARCHAR(2) NOT NULL,
    version INTEGER NOT NULL,
    effective_from TIMESTAMP NOT NULL,
    effective_to TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    table_data JSONB NOT NULL,
    source_reference TEXT,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(country, version)
);

CREATE INDEX idx_tax_tables_country ON tax_tables(country);
CREATE INDEX idx_tax_tables_status ON tax_tables(status);
CREATE INDEX idx_tax_tables_effective ON tax_tables(effective_from, effective_to);
CREATE INDEX idx_tax_tables_data ON tax_tables USING GIN(table_data);

-- Cases table
CREATE TABLE IF NOT EXISTS cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'evaluated', 'completed')),
    answers JSONB,
    evaluation JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cases_user_id ON cases(user_id);
CREATE INDEX idx_cases_status ON cases(status);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_case_id ON messages(case_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Reports table
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'generating', 'completed', 'failed')),
    storage_url TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_case_id ON reports(case_id);
CREATE INDEX idx_reports_status ON reports(status);

-- Audit log table (append-only)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_name VARCHAR(100) NOT NULL,
    operation VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    user_id VARCHAR(255),
    request_id VARCHAR(255),
    correlation_id VARCHAR(255),
    details JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_service ON audit_logs(service_name);
CREATE INDEX idx_audit_logs_operation ON audit_logs(operation);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_correlation ON audit_logs(correlation_id);

-- Run migration 002 (path relative to initdb.d in container)
\i /docker-entrypoint-initdb.d/migrations/002_onboarding_and_dsl.sql

-- Run seeds
\i /docker-entrypoint-initdb.d/seeds/001_initial_personas_and_questions.sql
\i /docker-entrypoint-initdb.d/seeds/002_initial_questionnaires.sql
\i /docker-entrypoint-initdb.d/seeds/003_scenario_rules.sql
\i /docker-entrypoint-initdb.d/seeds/004_comprehensive_ptbr_rule_packs.sql
\i /docker-entrypoint-initdb.d/seeds/005_tax_tables_pt_br.sql
\i /docker-entrypoint-initdb.d/seeds/006_treaties_and_rules_minimal.sql