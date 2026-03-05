-- Seed platform_config so GetDefaultCountry() and supported countries exist (idempotent).
-- Prevents INSUFFICIENT_DATA on evaluate when table was empty after 011.

INSERT INTO platform_config (key, value, updated_at)
VALUES
  (
    'supported_countries',
    '[
      {
        "code": "PT",
        "name_pt": "Portugal",
        "name_en": "Portugal",
        "currency": "EUR",
        "order_index": 1,
        "tax_authority": "AT - Autoridade Tributária",
        "tax_system": "IRS",
        "has_cfc_rules": true,
        "fallback_tax_rates": {
          "salary":        { "min_rate": 0.14, "max_rate": 0.48 },
          "dividends":     { "min_rate": 0.28, "max_rate": 0.28 },
          "capital_gains": { "min_rate": 0.28, "max_rate": 0.28 },
          "other":         { "min_rate": 0.14, "max_rate": 0.28 }
        }
      },
      {
        "code": "BR",
        "name_pt": "Brasil",
        "name_en": "Brazil",
        "currency": "BRL",
        "order_index": 2,
        "tax_authority": "Receita Federal",
        "tax_system": "IRPF",
        "has_cfc_rules": false,
        "fallback_tax_rates": {
          "salary":        { "min_rate": 0.075, "max_rate": 0.275 },
          "dividends":     { "min_rate": 0.15,  "max_rate": 0.15  },
          "capital_gains": { "min_rate": 0.15,  "max_rate": 0.225 },
          "other":         { "min_rate": 0.075, "max_rate": 0.275 }
        }
      }
    ]'::jsonb,
    NOW()
  ),
  ('default_country_pair', '"PT-BR"'::jsonb, NOW()),
  ('default_country', '"PT"'::jsonb, NOW())
ON CONFLICT (key) DO UPDATE SET
  value      = EXCLUDED.value,
  updated_at = EXCLUDED.updated_at;
