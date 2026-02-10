-- Seed initial personas and questions

-- Personas
INSERT INTO personas (id, code, name_pt, name_en, description_pt, description_en, enabled, created_at, updated_at)
VALUES
  (uuid_generate_v4(), 'individual_ptbr', 'Indivíduo PT-BR', 'PT-BR Individual', 'Pessoa física com situação fiscal entre Portugal e Brasil', 'Individual with tax situation between Portugal and Brazil', true, NOW(), NOW()),
  (uuid_generate_v4(), 'company_ptbr', 'Empresa PT-BR', 'PT-BR Company', 'Empresa com operações entre Portugal e Brasil', 'Company with operations between Portugal and Brazil', true, NOW(), NOW()),
  (uuid_generate_v4(), 'expat_pt', 'Expatriado em Portugal', 'Expatriate in Portugal', 'Pessoa que se mudou para Portugal', 'Person who moved to Portugal', true, NOW(), NOW()),
  (uuid_generate_v4(), 'expat_br', 'Expatriado no Brasil', 'Expatriate in Brazil', 'Pessoa que se mudou para o Brasil', 'Person who moved to Brazil', true, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- Questions
DO $$
DECLARE
  q1_id UUID;
  q2_id UUID;
  q3_id UUID;
  q4_id UUID;
  q5_id UUID;
  q6_id UUID;
  q7_id UUID;
BEGIN
  -- Question 1: Current country of residence
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'current_country', 'select', true, 1, NOW(), NOW())
  RETURNING id INTO q1_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q1_id, 'pt', 'Qual é o seu país de residência atual?', 'País onde você reside atualmente'),
    (q1_id, 'en', 'What is your current country of residence?', 'Country where you currently reside');

  INSERT INTO question_options (id, question_id, value, order_index, created_at)
  VALUES
    (uuid_generate_v4(), q1_id, 'PT', 1, NOW()),
    (uuid_generate_v4(), q1_id, 'BR', 2, NOW()),
    (uuid_generate_v4(), q1_id, 'OTHER', 3, NOW());

  INSERT INTO question_option_translations (option_id, language, label)
  SELECT o.id, 'pt', 'Portugal' FROM question_options o WHERE o.question_id = q1_id AND o.value = 'PT'
  UNION ALL
  SELECT o.id, 'en', 'Portugal' FROM question_options o WHERE o.question_id = q1_id AND o.value = 'PT'
  UNION ALL
  SELECT o.id, 'pt', 'Brasil' FROM question_options o WHERE o.question_id = q1_id AND o.value = 'BR'
  UNION ALL
  SELECT o.id, 'en', 'Brazil' FROM question_options o WHERE o.question_id = q1_id AND o.value = 'BR'
  UNION ALL
  SELECT o.id, 'pt', 'Outro' FROM question_options o WHERE o.question_id = q1_id AND o.value = 'OTHER'
  UNION ALL
  SELECT o.id, 'en', 'Other' FROM question_options o WHERE o.question_id = q1_id AND o.value = 'OTHER';

  -- Question 2: Days in Portugal (12 months)
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'days_in_portugal_12m', 'number', true, 2, NOW(), NOW())
  RETURNING id INTO q2_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q2_id, 'pt', 'Quantos dias você passou em Portugal nos últimos 12 meses?', 'Inclua todos os dias, mesmo que parcialmente'),
    (q2_id, 'en', 'How many days did you spend in Portugal in the last 12 months?', 'Include all days, even if partial');

  -- Question 3: Days in Brazil (12 months)
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'days_in_brazil_12m', 'number', true, 3, NOW(), NOW())
  RETURNING id INTO q3_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q3_id, 'pt', 'Quantos dias você passou no Brasil nos últimos 12 meses?', 'Inclua todos os dias, mesmo que parcialmente'),
    (q3_id, 'en', 'How many days did you spend in Brazil in the last 12 months?', 'Include all days, even if partial');

  -- Question 4: Has permanent home
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'has_permanent_home', 'boolean', true, 4, NOW(), NOW())
  RETURNING id INTO q4_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q4_id, 'pt', 'Você possui residência permanente em algum país?', 'Casa ou apartamento de propriedade ou alugado permanentemente'),
    (q4_id, 'en', 'Do you have a permanent home in any country?', 'House or apartment owned or permanently rented');

  -- Question 5: Center of vital interests
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'center_vital_interests', 'select', false, 5, NOW(), NOW())
  RETURNING id INTO q5_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q5_id, 'pt', 'Onde está o centro dos seus interesses vitais?', 'Onde estão seus familiares, bens pessoais, atividades econômicas principais'),
    (q5_id, 'en', 'Where is the center of your vital interests?', 'Where are your family, personal assets, main economic activities');

  INSERT INTO question_options (id, question_id, value, order_index, created_at)
  VALUES
    (uuid_generate_v4(), q5_id, 'PT', 1, NOW()),
    (uuid_generate_v4(), q5_id, 'BR', 2, NOW()),
    (uuid_generate_v4(), q5_id, 'BOTH', 3, NOW()),
    (uuid_generate_v4(), q5_id, 'OTHER', 4, NOW());

  INSERT INTO question_option_translations (option_id, language, label)
  SELECT o.id, 'pt', 'Portugal' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'PT'
  UNION ALL
  SELECT o.id, 'en', 'Portugal' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'PT'
  UNION ALL
  SELECT o.id, 'pt', 'Brasil' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'BR'
  UNION ALL
  SELECT o.id, 'en', 'Brazil' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'BR'
  UNION ALL
  SELECT o.id, 'pt', 'Ambos' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'BOTH'
  UNION ALL
  SELECT o.id, 'en', 'Both' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'BOTH'
  UNION ALL
  SELECT o.id, 'pt', 'Outro' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'OTHER'
  UNION ALL
  SELECT o.id, 'en', 'Other' FROM question_options o WHERE o.question_id = q5_id AND o.value = 'OTHER';

  -- Question 6: Annual salary in Portugal
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'annual_salary_portugal', 'number', false, 6, NOW(), NOW())
  RETURNING id INTO q6_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q6_id, 'pt', 'Qual o seu salário anual em Portugal? (EUR)', 'Valor em euros, 0 se não aplicável'),
    (q6_id, 'en', 'What is your annual salary in Portugal? (EUR)', 'Amount in euros, 0 if not applicable');

  -- Question 7: Annual salary in Brazil
  INSERT INTO questions (id, code, type, required, order_index, created_at, updated_at)
  VALUES (uuid_generate_v4(), 'annual_salary_brazil', 'number', false, 7, NOW(), NOW())
  RETURNING id INTO q7_id;

  INSERT INTO question_translations (question_id, language, title, help_text)
  VALUES
    (q7_id, 'pt', 'Qual o seu salário anual no Brasil? (BRL)', 'Valor em reais, 0 se não aplicável'),
    (q7_id, 'en', 'What is your annual salary in Brazil? (BRL)', 'Amount in reais, 0 if not applicable');
END $$;
