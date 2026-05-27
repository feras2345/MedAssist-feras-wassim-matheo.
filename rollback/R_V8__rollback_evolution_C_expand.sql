-- ==========================================================================
-- ROLLBACK V8 : Annulation Évolution C – EXPAND
-- ==========================================================================
DROP TRIGGER IF EXISTS trg_sync_gender ON patients;
DROP FUNCTION IF EXISTS fn_sync_gender();
ALTER TABLE patients DROP CONSTRAINT IF EXISTS chk_gender_new;
ALTER TABLE patients DROP COLUMN IF EXISTS gender_new;
