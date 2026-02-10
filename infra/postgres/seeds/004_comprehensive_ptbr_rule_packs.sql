-- Comprehensive Rule Packs for PT-BR Treaty Analysis
-- This script creates multiple rule packs covering all possible scenarios for all personas
-- Based on the PT-BR tax treaty provisions

DO $$
DECLARE
  -- Rule Pack IDs
  residency_pack_id UUID;
  effective_management_pack_id UUID;
  cfc_risk_pack_id UUID;
  treaty_applicability_pack_id UUID;
  scenario_generation_pack_id UUID;
  income_taxation_pack_id UUID;
  
  -- Version IDs
  residency_version_id UUID;
  effective_management_version_id UUID;
  cfc_risk_version_id UUID;
  treaty_applicability_version_id UUID;
  scenario_generation_version_id UUID;
  income_taxation_version_id UUID;
  
  current_year INTEGER;
BEGIN
  current_year := EXTRACT(YEAR FROM NOW())::INTEGER;

  -- ============================================================================
  -- RULE PACK 1: Tax Residency Determination (PT-BR Treaty)
  -- ============================================================================
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'ptbr_residency_determination',
    'PT-BR Tax Residency Determination',
    ARRAY['PT', 'BR'],
    current_year,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO residency_pack_id;

  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    residency_pack_id,
    1,
    'published',
    jsonb_build_object(
      'dsl_version', '0.1',
      'pack', jsonb_build_object(
        'id', 'ptbr_residency_determination',
        'country_scope', jsonb_build_array('PT', 'BR'),
        'fiscal_year', current_year
      ),
      'rules', jsonb_build_array(
        -- Rule: Likely residency if 183+ days in country
        jsonb_build_object(
          'id', 'residency_183_days',
          'priority', 100,
          'enabled', true,
          'when', jsonb_build_object(
            'any', jsonb_build_array(
              jsonb_build_object('fact', 'profile.days_in_country', 'op', 'gte', 'value', 183),
              jsonb_build_object('fact', 'mobility.days_in_portugal_12m', 'op', 'gte', 'value', 183),
              jsonb_build_object('fact', 'mobility.days_in_brazil_12m', 'op', 'gte', 'value', 183)
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.residency', 'value', 'LIKELY')),
            jsonb_build_object('score', jsonb_build_object('name', 'residency_score', 'value', 0.9)),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'RESIDENCY_183_DAYS',
              'severity', 'info',
              'message', jsonb_build_object(
                'pt', 'Residência fiscal provável devido a 183+ dias no país',
                'en', 'Tax residency likely due to 183+ days in country'
              )
            ))
          )
        ),
        -- Rule: Likely residency if permanent home
        jsonb_build_object(
          'id', 'residency_permanent_home',
          'priority', 95,
          'enabled', true,
          'when', jsonb_build_object(
            'any', jsonb_build_array(
              jsonb_build_object('fact', 'profile.has_habitual_home', 'op', 'is_true'),
              jsonb_build_object('fact', 'personal.has_permanent_home', 'op', 'is_true')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.residency', 'value', 'LIKELY')),
            jsonb_build_object('score', jsonb_build_object('name', 'residency_score', 'value', 0.85)),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'RESIDENCY_PERMANENT_HOME',
              'severity', 'info',
              'message', jsonb_build_object(
                'pt', 'Residência fiscal provável devido a residência permanente',
                'en', 'Tax residency likely due to permanent home'
              )
            ))
          )
        ),
        -- Rule: Possible residency for expats
        jsonb_build_object(
          'id', 'residency_expat_possible',
          'priority', 70,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'in', 'value', jsonb_build_array('expat_pt', 'expat_br')),
              jsonb_build_object('fact', 'profile.days_in_country', 'op', 'gte', 'value', 90),
              jsonb_build_object('fact', 'profile.days_in_country', 'op', 'lt', 'value', 183)
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.residency', 'value', 'POSSIBLE')),
            jsonb_build_object('score', jsonb_build_object('name', 'residency_score', 'value', 0.6)),
            jsonb_build_object('tag', 'scenario:change_residency')
          )
        )
      )
    ),
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO residency_version_id;

  -- ============================================================================
  -- RULE PACK 2: Effective Management Risk (PT-BR Treaty)
  -- ============================================================================
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'ptbr_effective_management',
    'PT-BR Effective Management Risk',
    ARRAY['PT', 'BR'],
    current_year,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO effective_management_pack_id;

  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    effective_management_pack_id,
    1,
    'published',
    jsonb_build_object(
      'dsl_version', '0.1',
      'pack', jsonb_build_object(
        'id', 'ptbr_effective_management',
        'country_scope', jsonb_build_array('PT', 'BR'),
        'fiscal_year', current_year
      ),
      'rules', jsonb_build_array(
        -- Rule: High risk if company in different country and works from residency
        jsonb_build_object(
          'id', 'effective_management_high_risk',
          'priority', 90,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'profile.company_country', 'op', 'exists'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'neq', 'value', jsonb_build_object('fact', 'profile.country')),
              jsonb_build_object('fact', 'profile.works_from_residency', 'op', 'is_true')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.effective_management_risk', 'value', 'HIGH')),
            jsonb_build_object('score', jsonb_build_object('name', 'effective_management_score', 'value', 0.9)),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'EFFECTIVE_MANAGEMENT_HIGH',
              'severity', 'warning',
              'message', jsonb_build_object(
                'pt', 'Alto risco de gestão efetiva: empresa em país diferente e trabalho realizado no país de residência',
                'en', 'High effective management risk: company in different country and work performed in residency country'
              )
            )),
            jsonb_build_object('tag', 'scenario:stay_resident_foreign_company')
          )
        ),
        -- Rule: Medium risk for company personas
        jsonb_build_object(
          'id', 'effective_management_medium_risk',
          'priority', 75,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'eq', 'value', 'company_ptbr'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'exists'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'neq', 'value', jsonb_build_object('fact', 'profile.country'))
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.effective_management_risk', 'value', 'MEDIUM')),
            jsonb_build_object('score', jsonb_build_object('name', 'effective_management_score', 'value', 0.6))
          )
        )
      )
    ),
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO effective_management_version_id;

  -- ============================================================================
  -- RULE PACK 3: CFC Risk (PT-BR Treaty)
  -- ============================================================================
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'ptbr_cfc_risk',
    'PT-BR CFC (Controlled Foreign Company) Risk',
    ARRAY['PT', 'BR'],
    current_year,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO cfc_risk_pack_id;

  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    cfc_risk_pack_id,
    1,
    'published',
    jsonb_build_object(
      'dsl_version', '0.1',
      'pack', jsonb_build_object(
        'id', 'ptbr_cfc_risk',
        'country_scope', jsonb_build_array('PT', 'BR'),
        'fiscal_year', current_year
      ),
      'rules', jsonb_build_array(
        -- Rule: High CFC risk for PT residents with BR company
        jsonb_build_object(
          'id', 'cfc_risk_pt_resident_br_company',
          'priority', 95,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'profile.country', 'op', 'eq', 'value', 'PT'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'eq', 'value', 'BR'),
              jsonb_build_object('fact', 'profile.ownership_percentage', 'op', 'gte', 'value', 25)
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.cfc_risk', 'value', 'HIGH')),
            jsonb_build_object('score', jsonb_build_object('name', 'cfc_risk_score', 'value', 0.9)),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'CFC_RISK_HIGH_PT_BR',
              'severity', 'warning',
              'message', jsonb_build_object(
                'pt', 'Alto risco CFC: residente em PT com empresa no BR e participação >= 25%',
                'en', 'High CFC risk: PT resident with BR company and ownership >= 25%'
              )
            ))
          )
        ),
        -- Rule: High CFC risk for BR residents with PT company
        jsonb_build_object(
          'id', 'cfc_risk_br_resident_pt_company',
          'priority', 95,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'profile.country', 'op', 'eq', 'value', 'BR'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'eq', 'value', 'PT'),
              jsonb_build_object('fact', 'profile.ownership_percentage', 'op', 'gte', 'value', 25)
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'evaluation.cfc_risk', 'value', 'HIGH')),
            jsonb_build_object('score', jsonb_build_object('name', 'cfc_risk_score', 'value', 0.9)),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'CFC_RISK_HIGH_BR_PT',
              'severity', 'warning',
              'message', jsonb_build_object(
                'pt', 'Alto risco CFC: residente no BR com empresa em PT e participação >= 25%',
                'en', 'High CFC risk: BR resident with PT company and ownership >= 25%'
              )
            ))
          )
        )
      )
    ),
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO cfc_risk_version_id;

  -- ============================================================================
  -- RULE PACK 4: Treaty Applicability (PT-BR Treaty)
  -- ============================================================================
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'ptbr_treaty_applicability',
    'PT-BR Treaty Applicability Rules',
    ARRAY['PT', 'BR'],
    current_year,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO treaty_applicability_pack_id;

  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    treaty_applicability_pack_id,
    1,
    'published',
    jsonb_build_object(
      'dsl_version', '0.1',
      'pack', jsonb_build_object(
        'id', 'ptbr_treaty_applicability',
        'country_scope', jsonb_build_array('PT', 'BR'),
        'fiscal_year', current_year
      ),
      'rules', jsonb_build_array(
        -- Rule: Treaty applies when both countries involved
        jsonb_build_object(
          'id', 'treaty_applicable_pt_br',
          'priority', 100,
          'enabled', true,
          'when', jsonb_build_object(
            'any', jsonb_build_array(
              jsonb_build_object(
                'all', jsonb_build_array(
                  jsonb_build_object('fact', 'profile.country', 'op', 'in', 'value', jsonb_build_array('PT', 'BR')),
                  jsonb_build_object('fact', 'profile.income_source_country', 'op', 'in', 'value', jsonb_build_array('PT', 'BR'))
                )
              ),
              jsonb_build_object(
                'all', jsonb_build_array(
                  jsonb_build_object('fact', 'profile.country', 'op', 'in', 'value', jsonb_build_array('PT', 'BR')),
                  jsonb_build_object('fact', 'profile.company_country', 'op', 'in', 'value', jsonb_build_array('PT', 'BR'))
                )
              )
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'treaty.applicable', 'value', true)),
            jsonb_build_object('set', jsonb_build_object('path', 'treaty.country_pair', 'value', 'PT-BR')),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'TREATY_PT_BR_APPLICABLE',
              'severity', 'info',
              'message', jsonb_build_object(
                'pt', 'Convênio PT-BR aplicável à situação fiscal',
                'en', 'PT-BR treaty applicable to tax situation'
              )
            ))
          )
        )
      )
    ),
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO treaty_applicability_version_id;

  -- ============================================================================
  -- RULE PACK 5: Comprehensive Scenario Generation (PT-BR Treaty)
  -- ============================================================================
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'ptbr_comprehensive_scenarios',
    'PT-BR Comprehensive Scenario Generation',
    ARRAY['PT', 'BR'],
    current_year,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO scenario_generation_pack_id;

  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    scenario_generation_pack_id,
    1,
    'published',
    jsonb_build_object(
      'dsl_version', '0.1',
      'pack', jsonb_build_object(
        'id', 'ptbr_comprehensive_scenarios',
        'country_scope', jsonb_build_array('PT', 'BR'),
        'fiscal_year', current_year
      ),
      'rules', jsonb_build_array(
        -- Scenario 1: Stay Resident with Foreign Company (Company Personas)
        jsonb_build_object(
          'id', 'scenario_stay_resident_foreign_company',
          'priority', 85,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'eq', 'value', 'company_ptbr'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'exists'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'neq', 'value', jsonb_build_object('fact', 'profile.country')),
              jsonb_build_object('fact', 'evaluation.residency', 'op', 'eq', 'value', 'LIKELY')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('tag', 'scenario:stay_resident_foreign_company'),
            jsonb_build_object('score', jsonb_build_object('name', 'scenario_relevance', 'value', 0.9))
          )
        ),
        -- Scenario 2: Change Residency (All Personas)
        jsonb_build_object(
          'id', 'scenario_change_residency',
          'priority', 80,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'exists'),
              jsonb_build_object('fact', 'evaluation.residency', 'op', 'in', 'value', jsonb_build_array('POSSIBLE', 'UNLIKELY'))
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('tag', 'scenario:change_residency'),
            jsonb_build_object('score', jsonb_build_object('name', 'scenario_relevance', 'value', 0.8))
          )
        ),
        -- Scenario 3: Establish Local Company (Company Personas)
        jsonb_build_object(
          'id', 'scenario_establish_local_company',
          'priority', 75,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'eq', 'value', 'company_ptbr'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'exists'),
              jsonb_build_object('fact', 'profile.company_country', 'op', 'neq', 'value', jsonb_build_object('fact', 'profile.country')),
              jsonb_build_object('fact', 'evaluation.effective_management_risk', 'op', 'in', 'value', jsonb_build_array('HIGH', 'MEDIUM'))
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('tag', 'scenario:establish_local_company'),
            jsonb_build_object('score', jsonb_build_object('name', 'scenario_relevance', 'value', 0.85))
          )
        ),
        -- Scenario 4: Stay Current Resident (Individual/Expat Personas)
        jsonb_build_object(
          'id', 'scenario_stay_current_resident',
          'priority', 70,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'in', 'value', jsonb_build_array('individual_ptbr', 'expat_pt', 'expat_br')),
              jsonb_build_object('fact', 'evaluation.residency', 'op', 'eq', 'value', 'LIKELY'),
              jsonb_build_object('fact', 'evaluation.effective_management_risk', 'op', 'neq', 'value', 'HIGH'),
              jsonb_build_object('fact', 'evaluation.cfc_risk', 'op', 'neq', 'value', 'HIGH')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('tag', 'scenario:stay_current_resident'),
            jsonb_build_object('score', jsonb_build_object('name', 'scenario_relevance', 'value', 0.7))
          )
        ),
        -- Scenario 5: Change Residency for Expat PT (when residency is unlikely)
        jsonb_build_object(
          'id', 'scenario_change_residency_expat_pt',
          'priority', 65,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'eq', 'value', 'expat_pt'),
              jsonb_build_object('fact', 'profile.country', 'op', 'eq', 'value', 'BR'),
              jsonb_build_object('fact', 'evaluation.residency', 'op', 'eq', 'value', 'UNLIKELY')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('tag', 'scenario:change_residency'),
            jsonb_build_object('score', jsonb_build_object('name', 'scenario_relevance', 'value', 0.9))
          )
        ),
        -- Scenario 6: Change Residency for Expat BR (when residency is unlikely)
        jsonb_build_object(
          'id', 'scenario_change_residency_expat_br',
          'priority', 65,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'persona.code', 'op', 'eq', 'value', 'expat_br'),
              jsonb_build_object('fact', 'profile.country', 'op', 'eq', 'value', 'PT'),
              jsonb_build_object('fact', 'evaluation.residency', 'op', 'eq', 'value', 'UNLIKELY')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('tag', 'scenario:change_residency'),
            jsonb_build_object('score', jsonb_build_object('name', 'scenario_relevance', 'value', 0.9))
          )
        )
      )
    ),
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO scenario_generation_version_id;

  -- ============================================================================
  -- RULE PACK 6: Income Taxation Rules (PT-BR Treaty)
  -- ============================================================================
  INSERT INTO rule_packs (id, code, name, country_scope, fiscal_year, enabled, created_at, updated_at)
  VALUES (
    uuid_generate_v4(),
    'ptbr_income_taxation',
    'PT-BR Income Taxation Rules',
    ARRAY['PT', 'BR'],
    current_year,
    true,
    NOW(),
    NOW()
  )
  RETURNING id INTO income_taxation_pack_id;

  INSERT INTO rule_pack_versions (id, rule_pack_id, version, status, rules_json, created_by, created_at, published_at)
  VALUES (
    uuid_generate_v4(),
    income_taxation_pack_id,
    1,
    'published',
    jsonb_build_object(
      'dsl_version', '0.1',
      'pack', jsonb_build_object(
        'id', 'ptbr_income_taxation',
        'country_scope', jsonb_build_array('PT', 'BR'),
        'fiscal_year', current_year
      ),
      'rules', jsonb_build_array(
        -- Rule: Employment income taxed in country of residence
        jsonb_build_object(
          'id', 'income_employment_residence',
          'priority', 90,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'income.type', 'op', 'eq', 'value', 'employment'),
              jsonb_build_object('fact', 'profile.country', 'op', 'in', 'value', jsonb_build_array('PT', 'BR')),
              jsonb_build_object('fact', 'profile.income_source_country', 'op', 'eq', 'value', jsonb_build_object('fact', 'profile.country'))
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'income.taxation_country', 'value', jsonb_build_object('fact', 'profile.country'))),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'INCOME_TAXED_RESIDENCE',
              'severity', 'info',
              'message', jsonb_build_object(
                'pt', 'Rendimentos de trabalho assalariado tributados no país de residência',
                'en', 'Employment income taxed in country of residence'
              )
            ))
          )
        ),
        -- Rule: Business profits taxed where PE exists
        jsonb_build_object(
          'id', 'income_business_pe',
          'priority', 85,
          'enabled', true,
          'when', jsonb_build_object(
            'all', jsonb_build_array(
              jsonb_build_object('fact', 'income.type', 'op', 'eq', 'value', 'business'),
              jsonb_build_object('fact', 'business.has_permanent_establishment', 'op', 'is_true')
            )
          ),
          'then', jsonb_build_array(
            jsonb_build_object('set', jsonb_build_object('path', 'income.taxation_country', 'value', jsonb_build_object('fact', 'business.pe_country'))),
            jsonb_build_object('flag', jsonb_build_object(
              'code', 'INCOME_TAXED_PE',
              'severity', 'info',
              'message', jsonb_build_object(
                'pt', 'Lucros empresariais tributados onde existe estabelecimento permanente',
                'en', 'Business profits taxed where permanent establishment exists'
              )
            ))
          )
        )
      )
    ),
    'system',
    NOW(),
    NOW()
  )
  RETURNING id INTO income_taxation_version_id;

  RAISE NOTICE 'Created 6 comprehensive rule packs for PT-BR treaty analysis';
  RAISE NOTICE 'Rule Pack 1 (Residency): %', residency_pack_id;
  RAISE NOTICE 'Rule Pack 2 (Effective Management): %', effective_management_pack_id;
  RAISE NOTICE 'Rule Pack 3 (CFC Risk): %', cfc_risk_pack_id;
  RAISE NOTICE 'Rule Pack 4 (Treaty Applicability): %', treaty_applicability_pack_id;
  RAISE NOTICE 'Rule Pack 5 (Scenarios): %', scenario_generation_pack_id;
  RAISE NOTICE 'Rule Pack 6 (Income Taxation): %', income_taxation_pack_id;
END $$;
