-- Migration 004: Add salary questions (q6, q7) for DBs that were seeded with only 5 questions.
-- Safe to run multiple times (inserts only if question code does not exist).

DO $$
DECLARE
  q6_id UUID;
  q7_id UUID;
  qv RECORD;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM questions WHERE code = 'annual_salary_portugal') THEN
    INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
    VALUES (uuid_generate_v4(), 'annual_salary_portugal', 'number', false, 6, NOW(), NOW())
    RETURNING id INTO q6_id;
    INSERT INTO question_translations (question_id, language, title, help_text)
    VALUES
      (q6_id, 'pt', 'Qual o seu salário anual em Portugal? (EUR)', 'Valor em euros, 0 se não aplicável'),
      (q6_id, 'en', 'What is your annual salary in Portugal? (EUR)', 'Amount in euros, 0 if not applicable');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM questions WHERE code = 'annual_salary_brazil') THEN
    INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
    VALUES (uuid_generate_v4(), 'annual_salary_brazil', 'number', false, 7, NOW(), NOW())
    RETURNING id INTO q7_id;
    INSERT INTO question_translations (question_id, language, title, help_text)
    VALUES
      (q7_id, 'pt', 'Qual o seu salário anual no Brasil? (BRL)', 'Valor em reais, 0 se não aplicável'),
      (q7_id, 'en', 'What is your annual salary in Brazil? (BRL)', 'Amount in reais, 0 if not applicable');
  END IF;

  SELECT id INTO q6_id FROM questions WHERE code = 'annual_salary_portugal';
  SELECT id INTO q7_id FROM questions WHERE code = 'annual_salary_brazil';
  IF q6_id IS NULL OR q7_id IS NULL THEN
    RETURN;
  END IF;

  FOR qv IN
    SELECT DISTINCT qq.questionnaire_version_id
    FROM questionnaire_questions qq
    JOIN questions q ON q.id = qq.question_id AND q.code = 'center_vital_interests'
    WHERE NOT EXISTS (
      SELECT 1 FROM questionnaire_questions qq2
      WHERE qq2.questionnaire_version_id = qq.questionnaire_version_id AND qq2.question_id = q6_id
    )
  LOOP
    INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
    VALUES
      (uuid_generate_v4(), qv.questionnaire_version_id, q6_id, 'income.annual_salary_pt', 6, false),
      (uuid_generate_v4(), qv.questionnaire_version_id, q7_id, 'income.annual_salary_br', 7, false);
  END LOOP;
END $$;
