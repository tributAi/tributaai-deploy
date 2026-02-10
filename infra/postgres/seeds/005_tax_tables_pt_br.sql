-- Tax Tables for Portugal and Brazil
-- Based on official tax brackets for 2024/2025

DO $$
DECLARE
  pt_tax_table_id UUID;
  br_tax_table_id UUID;
  current_year INTEGER;
BEGIN
  current_year := EXTRACT(YEAR FROM NOW())::INTEGER;

  -- ============================================================================
  -- PORTUGAL: IRS (Imposto sobre Rendimento das Pessoas Singulares)
  -- ============================================================================
  INSERT INTO tax_tables (
    id,
    country,
    version,
    effective_from,
    effective_to,
    status,
    table_data,
    source_reference,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    uuid_generate_v4(),
    'PT',
    1,
    DATE '2024-01-01',
    DATE '2024-12-31',
    'published',
    jsonb_build_object(
      'name', 'IRS - Imposto sobre Rendimento das Pessoas Singulares',
      'year', 2024,
      'currency', 'EUR',
      'income_types', jsonb_build_object(
        'salary', jsonb_build_object(
          'type', 'progressive',
          'brackets', jsonb_build_array(
            jsonb_build_object('from', 0, 'to', 7112, 'rate', 0.145, 'description', 'Até 7.112€'),
            jsonb_build_object('from', 7112, 'to', 10732, 'rate', 0.21, 'description', 'De 7.112€ a 10.732€'),
            jsonb_build_object('from', 10732, 'to', 20322, 'rate', 0.265, 'description', 'De 10.732€ a 20.322€'),
            jsonb_build_object('from', 20322, 'to', 25075, 'rate', 0.285, 'description', 'De 20.322€ a 25.075€'),
            jsonb_build_object('from', 25075, 'to', 36967, 'rate', 0.37, 'description', 'De 25.075€ a 36.967€'),
            jsonb_build_object('from', 36967, 'to', 80882, 'rate', 0.45, 'description', 'De 36.967€ a 80.882€'),
            jsonb_build_object('from', 80882, 'to', null, 'rate', 0.48, 'description', 'Acima de 80.882€')
          )
        ),
        'dividends', jsonb_build_object(
          'type', 'flat',
          'rate', 0.28,
          'description', 'Taxa fixa de 28% sobre dividendos'
        ),
        'business_profits', jsonb_build_object(
          'type', 'progressive',
          'brackets', jsonb_build_array(
            jsonb_build_object('from', 0, 'to', 12500, 'rate', 0.0, 'description', 'Isento até 12.500€'),
            jsonb_build_object('from', 12500, 'to', 50000, 'rate', 0.17, 'description', 'De 12.500€ a 50.000€'),
            jsonb_build_object('from', 50000, 'to', null, 'rate', 0.21, 'description', 'Acima de 50.000€')
          )
        ),
        'capital_gains', jsonb_build_object(
          'type', 'flat',
          'rate', 0.28,
          'description', 'Taxa fixa de 28% sobre mais-valias'
        )
      ),
      'deductions', jsonb_build_object(
        'personal_allowance', 4104,
        'description', 'Deduções específicas e gerais aplicáveis'
      ),
      'source', 'Autoridade Tributária e Aduaneira (AT) - Portugal',
      'last_updated', '2024-01-01'
    ),
    'Portaria n.º 377/2023 - Tabela de Retenção na Fonte IRS 2024',
    'admin@tributa.ai',
    NOW(),
    NOW()
  )
  RETURNING id INTO pt_tax_table_id;

  -- ============================================================================
  -- BRAZIL: IRPF (Imposto de Renda Pessoa Física)
  -- ============================================================================
  INSERT INTO tax_tables (
    id,
    country,
    version,
    effective_from,
    effective_to,
    status,
    table_data,
    source_reference,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    uuid_generate_v4(),
    'BR',
    1,
    DATE '2024-01-01',
    DATE '2024-12-31',
    'published',
    jsonb_build_object(
      'name', 'IRPF - Imposto de Renda Pessoa Física',
      'year', 2024,
      'currency', 'BRL',
      'income_types', jsonb_build_object(
        'salary', jsonb_build_object(
          'type', 'progressive',
          'brackets', jsonb_build_array(
            jsonb_build_object('from', 0, 'to', 22847.76, 'rate', 0.0, 'description', 'Até R$ 22.847,76 - Isento'),
            jsonb_build_object('from', 22847.76, 'to', 33919.80, 'rate', 0.075, 'description', 'De R$ 22.847,77 a R$ 33.919,80 - 7,5%'),
            jsonb_build_object('from', 33919.80, 'to', 45012.60, 'rate', 0.15, 'description', 'De R$ 33.919,81 a R$ 45.012,60 - 15%'),
            jsonb_build_object('from', 45012.60, 'to', 55976.16, 'rate', 0.225, 'description', 'De R$ 45.012,61 a R$ 55.976,16 - 22,5%'),
            jsonb_build_object('from', 55976.16, 'to', null, 'rate', 0.275, 'description', 'Acima de R$ 55.976,16 - 27,5%')
          )
        ),
        'dividends', jsonb_build_object(
          'type', 'flat',
          'rate', 0.15,
          'description', 'Taxa fixa de 15% sobre dividendos (com retenção na fonte)'
        ),
        'business_profits', jsonb_build_object(
          'type', 'progressive',
          'brackets', jsonb_build_array(
            jsonb_build_object('from', 0, 'to', 60000, 'rate', 0.06, 'description', 'Simples Nacional - até R$ 60.000'),
            jsonb_build_object('from', 60000, 'to', 180000, 'rate', 0.112, 'description', 'Simples Nacional - de R$ 60.000 a R$ 180.000'),
            jsonb_build_object('from', 180000, 'to', 360000, 'rate', 0.135, 'description', 'Simples Nacional - de R$ 180.000 a R$ 360.000'),
            jsonb_build_object('from', 360000, 'to', 720000, 'rate', 0.16, 'description', 'Simples Nacional - de R$ 360.000 a R$ 720.000'),
            jsonb_build_object('from', 720000, 'to', 1800000, 'rate', 0.21, 'description', 'Simples Nacional - de R$ 720.000 a R$ 1.800.000'),
            jsonb_build_object('from', 1800000, 'to', 3600000, 'rate', 0.33, 'description', 'Simples Nacional - de R$ 1.800.000 a R$ 3.600.000'),
            jsonb_build_object('from', 3600000, 'to', null, 'rate', 0.34, 'description', 'Simples Nacional - acima de R$ 3.600.000')
          )
        ),
        'capital_gains', jsonb_build_object(
          'type', 'flat',
          'rate', 0.15,
          'description', 'Taxa fixa de 15% sobre ganhos de capital (acima de R$ 20.000 no mês)'
        )
      ),
      'deductions', jsonb_build_object(
        'personal_allowance', 22847.76,
        'dependent', 2275.08,
        'description', 'Deduções por dependente e despesas dedutíveis'
      ),
      'source', 'Receita Federal do Brasil - Instrução Normativa RFB nº 2.100/2023',
      'last_updated', '2024-01-01'
    ),
    'Instrução Normativa RFB nº 2.100/2023 - Tabela Progressiva IRPF 2024',
    'admin@tributa.ai',
    NOW(),
    NOW()
  )
  RETURNING id INTO br_tax_table_id;

  RAISE NOTICE 'Created tax tables for Portugal and Brazil';
  RAISE NOTICE 'Portugal Tax Table ID: %', pt_tax_table_id;
  RAISE NOTICE 'Brazil Tax Table ID: %', br_tax_table_id;
END $$;
