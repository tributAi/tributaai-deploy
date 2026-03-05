ALTER TABLE sophia_accounts ADD COLUMN is_super_admin BOOLEAN NOT NULL DEFAULT false;

UPDATE sophia_accounts SET is_super_admin = true WHERE email = 'eduardo@teste.com';
