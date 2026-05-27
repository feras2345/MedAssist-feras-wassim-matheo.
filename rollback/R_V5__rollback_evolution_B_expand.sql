-- ==========================================================================
-- ROLLBACK V5 : Annulation Évolution B – EXPAND
-- ==========================================================================
DROP TRIGGER IF EXISTS trg_sync_doctor_name ON consultations;
DROP FUNCTION IF EXISTS fn_sync_doctor_name_to_id();
DROP INDEX IF EXISTS idx_consultations_doctor;
ALTER TABLE consultations DROP COLUMN IF EXISTS doctor_id;
DROP TABLE IF EXISTS doctors;
