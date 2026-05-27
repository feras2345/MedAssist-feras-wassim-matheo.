-- ==========================================================================
-- ROLLBACK V6 : Annulation Évolution B – BACKFILL
-- ==========================================================================
UPDATE consultations SET doctor_id = NULL;
DELETE FROM doctors;
