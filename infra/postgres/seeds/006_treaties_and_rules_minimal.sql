-- Minimal seed for treaties and rules (legacy tables) so admin portal shows data locally.
-- Tax tables are in 005_tax_tables_pt_br.sql; rule_packs/rule_pack_versions in 003/004.

INSERT INTO treaties (
  id, country_pair, version, effective_from, effective_to, status,
  treaty_data, source_reference, created_by, created_at, updated_at
) VALUES (
  uuid_generate_v4(),
  'PT-BR',
  1,
  DATE '2024-01-01',
  NULL,
  'published',
  jsonb_build_object(
    'name', 'Convenção entre Portugal e Brasil para Evitar Dupla Tributação',
    'articles', jsonb_build_array(
      jsonb_build_object('id', '4', 'title', 'Residência', 'content', 'Critérios de residência fiscal'),
      jsonb_build_object('id', '5', 'title', 'Estabelecimento estável', 'content', 'Definição de estabelecimento estável'),
      jsonb_build_object('id', '6', 'title', 'Rendimentos imobiliários', 'content', 'Tributação no Estado da situação do imóvel')
    ),
    'last_updated', '2024-01-01'
  ),
  'Convenção PT-BR - seed local',
  'admin@tributa.ai',
  NOW(),
  NOW()
) ON CONFLICT (country_pair, version) DO NOTHING;

INSERT INTO rules (
  id, country, version, effective_from, effective_to, status,
  rule_data, source_reference, created_by, created_at, updated_at
) VALUES
  (
    uuid_generate_v4(),
    'PT',
    1,
    DATE '2024-01-01',
    NULL,
    'published',
    jsonb_build_object('residency', jsonb_build_object('days', 183), 'cfc', jsonb_build_object('threshold', 0.1)),
    'Código do IRC - seed local',
    'admin@tributa.ai',
    NOW(),
    NOW()
  ),
  (
    uuid_generate_v4(),
    'BR',
    1,
    DATE '2024-01-01',
    NULL,
    'published',
    jsonb_build_object('residency', jsonb_build_object('days', 183)),
    'Lei 9.249/1995 - seed local',
    'admin@tributa.ai',
    NOW(),
    NOW()
  )
ON CONFLICT (country, version) DO NOTHING;
