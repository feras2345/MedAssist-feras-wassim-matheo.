-- ==========================================================================
-- ROLLBACK V2 : Annulation Évolution A – EXPAND
-- ==========================================================================
DROP TRIGGER IF EXISTS trg_sync_patient_address ON patients;
DROP FUNCTION IF EXISTS fn_sync_patient_to_address();
DROP INDEX IF EXISTS idx_addresses_primary;
DROP INDEX IF EXISTS idx_addresses_patient;
DROP TABLE IF EXISTS addresses;
