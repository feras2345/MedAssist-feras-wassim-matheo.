-- ==========================================================================
-- ROLLBACK V11 : Annulation Évolution D – EXPAND
-- ==========================================================================
DROP TRIGGER IF EXISTS trg_sync_ssn_encrypt ON patients;
DROP FUNCTION IF EXISTS fn_sync_ssn_encrypt();
DROP INDEX IF EXISTS idx_patients_ssn_hash;
ALTER TABLE patients DROP COLUMN IF EXISTS ssn_hash;
ALTER TABLE patients DROP COLUMN IF EXISTS ssn_encrypted;
-- On ne supprime PAS l'extension pgcrypto (pourrait être utilisée ailleurs)
