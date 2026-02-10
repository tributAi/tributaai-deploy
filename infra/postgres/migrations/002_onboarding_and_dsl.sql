-- Migration 002: Onboarding and Rule Engine DSL
-- Adds personas, questionnaires, questions, rule_packs tables

-- Personas
CREATE TABLE IF NOT EXISTS personas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name_pt VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    description_pt TEXT,
    description_en TEXT,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Questionnaires
CREATE TABLE IF NOT EXISTS questionnaires (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name_pt VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    persona_id UUID REFERENCES personas(id),
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Questionnaire Versions
CREATE TABLE IF NOT EXISTS questionnaire_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    questionnaire_id UUID NOT NULL REFERENCES questionnaires(id),
    version INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    published_at TIMESTAMP,
    UNIQUE(questionnaire_id, version)
);

-- Questions
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('text', 'number', 'select', 'multi_select', 'date', 'boolean')),
    required BOOLEAN DEFAULT false,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Question Translations
CREATE TABLE IF NOT EXISTS question_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    language VARCHAR(2) NOT NULL CHECK (language IN ('pt', 'en')),
    title TEXT NOT NULL,
    help_text TEXT,
    UNIQUE(question_id, language)
);

-- Question Options (for select/multi-select)
CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    value VARCHAR(255) NOT NULL,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Question Option Translations
CREATE TABLE IF NOT EXISTS question_option_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    option_id UUID NOT NULL REFERENCES question_options(id) ON DELETE CASCADE,
    language VARCHAR(2) NOT NULL CHECK (language IN ('pt', 'en')),
    label TEXT NOT NULL,
    UNIQUE(option_id, language)
);

-- Questionnaire Question Mappings
CREATE TABLE IF NOT EXISTS questionnaire_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    questionnaire_version_id UUID NOT NULL REFERENCES questionnaire_versions(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES questions(id),
    rule_input_path VARCHAR(255) NOT NULL,
    order_index INTEGER NOT NULL,
    required BOOLEAN DEFAULT false,
    UNIQUE(questionnaire_version_id, question_id),
    UNIQUE(questionnaire_version_id, rule_input_path)
);

-- Rule Packs
CREATE TABLE IF NOT EXISTS rule_packs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    country_scope TEXT[] NOT NULL,
    fiscal_year INTEGER NOT NULL,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Rule Pack Versions
CREATE TABLE IF NOT EXISTS rule_pack_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_pack_id UUID NOT NULL REFERENCES rule_packs(id),
    version INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    rules_json JSONB NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    published_at TIMESTAMP,
    UNIQUE(rule_pack_id, version)
);

-- Rule Audit Log
CREATE TABLE IF NOT EXISTS rule_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    diff_json JSONB,
    actor_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Case Answers (normalized)
CREATE TABLE IF NOT EXISTS case_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id),
    rule_input_path VARCHAR(255) NOT NULL,
    answer_json JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(case_id, rule_input_path)
);

-- Update cases table
ALTER TABLE cases 
    ADD COLUMN IF NOT EXISTS language VARCHAR(2) CHECK (language IN ('pt', 'en')),
    ADD COLUMN IF NOT EXISTS persona_id UUID REFERENCES personas(id),
    ADD COLUMN IF NOT EXISTS context_json JSONB,
    ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMP;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_personas_code ON personas(code);
CREATE INDEX IF NOT EXISTS idx_personas_enabled ON personas(enabled);
CREATE INDEX IF NOT EXISTS idx_questionnaires_persona ON questionnaires(persona_id);
CREATE INDEX IF NOT EXISTS idx_questionnaires_code ON questionnaires(code);
CREATE INDEX IF NOT EXISTS idx_questionnaire_versions_status ON questionnaire_versions(status);
CREATE INDEX IF NOT EXISTS idx_questionnaire_versions_questionnaire ON questionnaire_versions(questionnaire_id);
CREATE INDEX IF NOT EXISTS idx_questions_code ON questions(code);
CREATE INDEX IF NOT EXISTS idx_questions_type ON questions(type);
CREATE INDEX IF NOT EXISTS idx_question_translations_question ON question_translations(question_id);
CREATE INDEX IF NOT EXISTS idx_question_options_question ON question_options(question_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_questions_version ON questionnaire_questions(questionnaire_version_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_questions_question ON questionnaire_questions(question_id);
CREATE INDEX IF NOT EXISTS idx_rule_packs_code ON rule_packs(code);
CREATE INDEX IF NOT EXISTS idx_rule_packs_country_scope ON rule_packs USING GIN(country_scope);
CREATE INDEX IF NOT EXISTS idx_rule_packs_fiscal_year ON rule_packs(fiscal_year);
CREATE INDEX IF NOT EXISTS idx_rule_pack_versions_status ON rule_pack_versions(status);
CREATE INDEX IF NOT EXISTS idx_rule_pack_versions_pack ON rule_pack_versions(rule_pack_id);
CREATE INDEX IF NOT EXISTS idx_rule_pack_versions_rules_json ON rule_pack_versions USING GIN(rules_json);
CREATE INDEX IF NOT EXISTS idx_case_answers_case ON case_answers(case_id);
CREATE INDEX IF NOT EXISTS idx_case_answers_path ON case_answers(rule_input_path);
CREATE INDEX IF NOT EXISTS idx_case_answers_question ON case_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_rule_audit_entity ON rule_audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_rule_audit_created ON rule_audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_cases_persona ON cases(persona_id);
CREATE INDEX IF NOT EXISTS idx_cases_language ON cases(language);
CREATE INDEX IF NOT EXISTS idx_cases_context_json ON cases USING GIN(context_json);
