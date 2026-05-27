-- ==========================================================================
-- ROLLBACK V12 : Annulation Évolution D – BACKFILL
-- ==========================================================================
UPDATE patients SET ssn_encrypted = NULL, ssn_hash = NULL;
