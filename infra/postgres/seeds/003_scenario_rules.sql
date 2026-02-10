-- Seed scenario rules rule pack
-- This script creates a rule pack with DSL rules to determine which scenarios should be shown

DO $$
DECLARE
  scenario_rules_pack_id UUID;
  scenario_rules_version_id UUID;
  rules_json JSONB;
BEGIN
  -- Create rule pack for scenario generation
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'scenario_rules',
    'Scenario Generation Rules',
    ARRAY['PT', 'BR'],
    EXTRACT(YEAR FROM NOW())::INTEGER,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO scenario_rules_pack_id;

  -- Build rules JSON
  rules_json := jsonb_build_object(
    'dsl_version', '0.1',
    'pack', jsonb_build_object(
      'id', 'scenario_rules',
      'country_scope', jsonb_build_array('PT', 'BR'),
      'fiscal_year', EXTRACT(YEAR FROM NOW())::INTEGER
    ),
    'rules', jsonb_build_array(
      -- Rule 1: Stay Resident with Foreign Company
      -- Only for company personas with company in different country
      jsonb_build_object(
        'id', 'scenario_stay_resident_foreign_company',
        'priority', 80,
        'enabled', true,
        'when', jsonb_build_object(
          'all', jsonb_build_array(
            jsonb_build_object('fact', 'persona.code', 'op', 'in', 'value', jsonb_build_array('company_ptbr')),
            jsonb_build_object('fact', 'profile.company_country', 'op', 'exists'),
            jsonb_build_object('fact', 'profile.company_country', 'op', 'neq', 'value', jsonb_build_object('fact', 'profile.country'))
          )
        ),
        'then', jsonb_build_array(
          jsonb_build_object('tag', 'scenario:stay_resident_foreign_company')
        )
      ),
      -- Rule 2: Change Residency to Target Country
      -- Always applicable for all personas
      jsonb_build_object(
        'id', 'scenario_change_residency',
        'priority', 70,
        'enabled', true,
        'when', jsonb_build_object(
          'all', jsonb_build_array(
            jsonb_build_object('fact', 'persona.code', 'op', 'exists')
          )
        ),
        'then', jsonb_build_array(
          jsonb_build_object('tag', 'scenario:change_residency')
        )
      ),
      -- Rule 3: Establish Local Company
      -- Only for company personas with company in different country
      jsonb_build_object(
        'id', 'scenario_establish_local_company',
        'priority', 75,
        'enabled', true,
        'when', jsonb_build_object(
          'all', jsonb_build_array(
            jsonb_build_object('fact', 'persona.code', 'op', 'in', 'value', jsonb_build_array('company_ptbr')),
            jsonb_build_object('fact', 'profile.company_country', 'op', 'exists'),
            jsonb_build_object('fact', 'profile.company_country', 'op', 'neq', 'value', jsonb_build_object('fact', 'profile.country'))
          )
        ),
        'then', jsonb_build_array(
          jsonb_build_object('tag', 'scenario:establish_local_company')
        )
      ),
      -- Rule 4: Stay Current Resident
      -- For individual personas when residency is likely
      jsonb_build_object(
        'id', 'scenario_stay_current_resident',
        'priority', 60,
        'enabled', true,
        'when', jsonb_build_object(
          'all', jsonb_build_array(
            jsonb_build_object('fact', 'persona.code', 'op', 'in', 'value', jsonb_build_array('individual_ptbr', 'expat_pt', 'expat_br')),
            jsonb_build_object('fact', 'evaluation.residency', 'op', 'eq', 'value', 'LIKELY')
          )
        ),
        'then', jsonb_build_array(
          jsonb_build_object('tag', 'scenario:stay_current_resident')
        )
      )
    )
  );

  -- Create rule pack version
  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    scenario_rules_pack_id,
    1,
    'published',
    rules_json,
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO scenario_rules_version_id;

  RAISE NOTICE 'Scenario rules rule pack created with ID: %', scenario_rules_pack_id;
END $$;
