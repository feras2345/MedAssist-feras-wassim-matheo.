-- ==========================================================================
-- V10 : Évolution C – CONTRACT – Remplacement de gender par gender_new
-- Stratégie : Expand-Contract (phase 3/3)
-- Risque : MOYEN – suppression et renommage de colonne
-- Downtime estimé : < 1 seconde
-- ==========================================================================

-- ── Suppression du trigger de synchronisation ──────────────────────────────
DROP TRIGGER IF EXISTS trg_sync_gender ON patients;
DROP FUNCTION IF EXISTS fn_sync_gender();

-- ── Suppression de l'ancienne colonne et contrainte ────────────────────────
ALTER TABLE patients DROP CONSTRAINT IF EXISTS patients_gender_check;
ALTER TABLE patients DROP COLUMN gender;

-- ── Renommage gender_new → gender ──────────────────────────────────────────
ALTER TABLE patients RENAME COLUMN gender_new TO gender;
