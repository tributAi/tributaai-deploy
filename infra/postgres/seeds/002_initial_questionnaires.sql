-- Seed initial questionnaires
-- This script creates questionnaires for each persona and associates questions

DO $$
DECLARE
  individual_ptbr_id UUID;
  company_ptbr_id UUID;
  expat_pt_id UUID;
  expat_br_id UUID;
  
  q1_id UUID; -- current_country
  q2_id UUID; -- days_in_portugal_12m
  q3_id UUID; -- days_in_brazil_12m
  q4_id UUID; -- has_permanent_home
  q5_id UUID; -- center_vital_interests
  q6_id UUID; -- annual_salary_portugal
  q7_id UUID; -- annual_salary_brazil
  
  qn1_id UUID;
  qn2_id UUID;
  qn3_id UUID;
  qn4_id UUID;
  qv1_id UUID;
  qv2_id UUID;
  qv3_id UUID;
  qv4_id UUID;
BEGIN
  -- Get persona IDs
  SELECT id INTO individual_ptbr_id FROM personas WHERE code = 'individual_ptbr';
  SELECT id INTO company_ptbr_id FROM personas WHERE code = 'company_ptbr';
  SELECT id INTO expat_pt_id FROM personas WHERE code = 'expat_pt';
  SELECT id INTO expat_br_id FROM personas WHERE code = 'expat_br';
  
  -- Get question IDs
  SELECT id INTO q1_id FROM questions WHERE code = 'current_country';
  SELECT id INTO q2_id FROM questions WHERE code = 'days_in_portugal_12m';
  SELECT id INTO q3_id FROM questions WHERE code = 'days_in_brazil_12m';
  SELECT id INTO q4_id FROM questions WHERE code = 'has_permanent_home';
  SELECT id INTO q5_id FROM questions WHERE code = 'center_vital_interests';
  SELECT id INTO q6_id FROM questions WHERE code = 'annual_salary_portugal';
  SELECT id INTO q7_id FROM questions WHERE code = 'annual_salary_brazil';
  
  -- Only proceed if personas and questions exist
  IF individual_ptbr_id IS NULL OR company_ptbr_id IS NULL OR expat_pt_id IS NULL OR expat_br_id IS NULL THEN
    RAISE NOTICE 'Personas not found. Skipping questionnaire creation.';
    RETURN;
  END IF;
  
  IF q1_id IS NULL OR q2_id IS NULL OR q3_id IS NULL OR q4_id IS NULL OR q5_id IS NULL THEN
    RAISE NOTICE 'Questions not found. Skipping questionnaire creation.';
    RETURN;
  END IF;
  
  -- Questionnaire 1: Individual PT-BR
  INSERT INTO questionnaires (id, code, name_pt, name_en, persona_id, enabled, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'questionnaire_individual_ptbr', 'Questionário Individual PT-BR', 'PT-BR Individual Questionnaire', individual_ptbr_id, true, NOW(), NOW())
  RETURNING id INTO qn1_id;

  INSERT INTO questionnaire_versions (id, questionnaire_id, version, status, created_by, created_at)
  VALUES (uuid_generate_v4(), qn1_id, 1, 'published', 'system', NOW())
  RETURNING id INTO qv1_id;

  UPDATE questionnaire_versions SET published_at = NOW() WHERE id = qv1_id;

  INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
  VALUES
    (uuid_generate_v4(), qv1_id, q1_id, 'personal.current_country', 1, true),
    (uuid_generate_v4(), qv1_id, q2_id, 'mobility.days_in_portugal_12m', 2, true),
    (uuid_generate_v4(), qv1_id, q3_id, 'mobility.days_in_brazil_12m', 3, true),
    (uuid_generate_v4(), qv1_id, q4_id, 'residency.has_permanent_home', 4, true),
    (uuid_generate_v4(), qv1_id, q5_id, 'residency.center_vital_interests', 5, false);
  IF q6_id IS NOT NULL AND q7_id IS NOT NULL THEN
    INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
    VALUES
      (uuid_generate_v4(), qv1_id, q6_id, 'income.annual_salary_pt', 6, false),
      (uuid_generate_v4(), qv1_id, q7_id, 'income.annual_salary_br', 7, false);
  END IF;

  -- Questionnaire 2: Company PT-BR
  INSERT INTO questionnaires (id, code, name_pt, name_en, persona_id, enabled, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'questionnaire_company_ptbr', 'Questionário Empresa PT-BR', 'PT-BR Company Questionnaire', company_ptbr_id, true, NOW(), NOW())
  RETURNING id INTO qn2_id;

  INSERT INTO questionnaire_versions (id, questionnaire_id, version, status, created_by, created_at)
  VALUES (uuid_generate_v4(), qn2_id, 1, 'published', 'system', NOW())
  RETURNING id INTO qv2_id;

  UPDATE questionnaire_versions SET published_at = NOW() WHERE id = qv2_id;

  INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
  VALUES
    (uuid_generate_v4(), qv2_id, q1_id, 'company.current_country', 1, true),
    (uuid_generate_v4(), qv2_id, q2_id, 'mobility.days_in_portugal_12m', 2, true),
    (uuid_generate_v4(), qv2_id, q3_id, 'mobility.days_in_brazil_12m', 3, true),
    (uuid_generate_v4(), qv2_id, q4_id, 'residency.has_permanent_home', 4, true),
    (uuid_generate_v4(), qv2_id, q5_id, 'residency.center_vital_interests', 5, false);
  IF q6_id IS NOT NULL AND q7_id IS NOT NULL THEN
    INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
    VALUES
      (uuid_generate_v4(), qv2_id, q6_id, 'income.annual_salary_pt', 6, false),
      (uuid_generate_v4(), qv2_id, q7_id, 'income.annual_salary_br', 7, false);
  END IF;

  -- Questionnaire 3: Expatriate in Portugal
  INSERT INTO questionnaires (id, code, name_pt, name_en, persona_id, enabled, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'questionnaire_expat_pt', 'Questionário Expatriado Portugal', 'Expatriate in Portugal Questionnaire', expat_pt_id, true, NOW(), NOW())
  RETURNING id INTO qn3_id;

  INSERT INTO questionnaire_versions (id, questionnaire_id, version, status, created_by, created_at)
  VALUES (uuid_generate_v4(), qn3_id, 1, 'published', 'system', NOW())
  RETURNING id INTO qv3_id;

  UPDATE questionnaire_versions SET published_at = NOW() WHERE id = qv3_id;

  INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
  VALUES
    (uuid_generate_v4(), qv3_id, q1_id, 'personal.current_country', 1, true),
    (uuid_generate_v4(), qv3_id, q2_id, 'mobility.days_in_portugal_12m', 2, true),
    (uuid_generate_v4(), qv3_id, q3_id, 'mobility.days_in_brazil_12m', 3, true),
    (uuid_generate_v4(), qv3_id, q4_id, 'residency.has_permanent_home', 4, true),
    (uuid_generate_v4(), qv3_id, q5_id, 'residency.center_vital_interests', 5, false);
  IF q6_id IS NOT NULL AND q7_id IS NOT NULL THEN
    INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
    VALUES
      (uuid_generate_v4(), qv3_id, q6_id, 'income.annual_salary_pt', 6, false),
      (uuid_generate_v4(), qv3_id, q7_id, 'income.annual_salary_br', 7, false);
  END IF;

  -- Questionnaire 4: Expatriate in Brazil
  INSERT INTO questionnaires (id, code, name_pt, name_en, persona_id, enabled, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'questionnaire_expat_br', 'Questionário Expatriado Brasil', 'Expatriate in Brazil Questionnaire', expat_br_id, true, NOW(), NOW())
  RETURNING id INTO qn4_id;

  INSERT INTO questionnaire_versions (id, questionnaire_id, version, status, created_by, created_at)
  VALUES (uuid_generate_v4(), qn4_id, 1, 'published', 'system', NOW())
  RETURNING id INTO qv4_id;

  UPDATE questionnaire_versions SET published_at = NOW() WHERE id = qv4_id;

  INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
  VALUES
    (uuid_generate_v4(), qv4_id, q1_id, 'personal.current_country', 1, true),
    (uuid_generate_v4(), qv4_id, q2_id, 'mobility.days_in_portugal_12m', 2, true),
    (uuid_generate_v4(), qv4_id, q3_id, 'mobility.days_in_brazil_12m', 3, true),
    (uuid_generate_v4(), qv4_id, q4_id, 'residency.has_permanent_home', 4, true),
    (uuid_generate_v4(), qv4_id, q5_id, 'residency.center_vital_interests', 5, false);
  IF q6_id IS NOT NULL AND q7_id IS NOT NULL THEN
    INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
    VALUES
      (uuid_generate_v4(), qv4_id, q6_id, 'income.annual_salary_pt', 6, false),
      (uuid_generate_v4(), qv4_id, q7_id, 'income.annual_salary_br', 7, false);
  END IF;

END $$;
