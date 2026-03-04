-- Migration 012: Add current_fiscal_residency question for residency analysis.
-- Safe to run multiple times (inserts only if question code does not exist).

DO $$
DECLARE
  q4b_id UUID;
  qv RECORD;
  max_ord INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM questions WHERE code = 'current_fiscal_residency') THEN
    INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
    VALUES (uuid_generate_v4(), 'current_fiscal_residency', 'select', false, 5, NOW(), NOW())
    RETURNING id INTO q4b_id;

    INSERT INTO question_translations (question_id, language, title, help_text)
    VALUES
      (q4b_id, 'pt', 'Qual é a sua atual residência fiscal?', 'Se nunca tratou deste assunto, é provável que seja no seu país de origem.'),
      (q4b_id, 'en', 'What is your current fiscal residency?', 'If you have never dealt with this, it is likely in your country of origin.');

    INSERT INTO question_options (id, question_id, value, order_index, created_at)
    VALUES
      (uuid_generate_v4(), q4b_id, 'PT', 1, NOW()),
      (uuid_generate_v4(), q4b_id, 'BR', 2, NOW()),
      (uuid_generate_v4(), q4b_id, 'UNKNOWN', 3, NOW());

    INSERT INTO question_option_translations (option_id, language, label)
    SELECT o.id, 'pt', 'Portugal' FROM question_options o WHERE o.question_id = q4b_id AND o.value = 'PT'
    UNION ALL
    SELECT o.id, 'en', 'Portugal' FROM question_options o WHERE o.question_id = q4b_id AND o.value = 'PT'
    UNION ALL
    SELECT o.id, 'pt', 'Brasil' FROM question_options o WHERE o.question_id = q4b_id AND o.value = 'BR'
    UNION ALL
    SELECT o.id, 'en', 'Brazil' FROM question_options o WHERE o.question_id = q4b_id AND o.value = 'BR'
    UNION ALL
    SELECT o.id, 'pt', 'Não sei' FROM question_options o WHERE o.question_id = q4b_id AND o.value = 'UNKNOWN'
    UNION ALL
    SELECT o.id, 'en', 'I don''t know' FROM question_options o WHERE o.question_id = q4b_id AND o.value = 'UNKNOWN';
  END IF;

  SELECT id INTO q4b_id FROM questions WHERE code = 'current_fiscal_residency';
  IF q4b_id IS NULL THEN
    RETURN;
  END IF;

  FOR qv IN
    SELECT DISTINCT qq.questionnaire_version_id
    FROM questionnaire_questions qq
    JOIN questions q ON q.id = qq.question_id AND q.code = 'has_permanent_home'
    WHERE NOT EXISTS (
      SELECT 1 FROM questionnaire_questions qq2
      JOIN questions q2 ON q2.id = qq2.question_id
      WHERE qq2.questionnaire_version_id = qq.questionnaire_version_id AND q2.code = 'current_fiscal_residency'
    )
  LOOP
    SELECT COALESCE(qq.order_index, 4) + 1 INTO max_ord
    FROM questionnaire_questions qq
    JOIN questions q ON q.id = qq.question_id AND q.code = 'has_permanent_home'
    WHERE qq.questionnaire_version_id = qv.questionnaire_version_id
    LIMIT 1;
    INSERT INTO questionnaire_questions (id, questionnaire_version_id, question_id, rule_input_path, order_index, required)
    VALUES (uuid_generate_v4(), qv.questionnaire_version_id, q4b_id, 'residency.current_fiscal_residency', max_ord, false);
  END LOOP;
END $$;
