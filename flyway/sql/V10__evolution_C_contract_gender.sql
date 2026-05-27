-- ==========================================================================
-- V10 : Évolution C – CONTRACT – Remplacement de gender par gender_new
-- Stratégie : Expand-Contract (phase 3/3)
-- Risque : MOYEN – suppression et renommage de colonne
-- Downtime estimé : < 1 seconde
-- ==========================================================================

-- ── Suppression du trigger de synchronisation ──────────────────────────────
DROP TRIGGER IF EXISTS trg_sync_gender ON patients;
DROP FUNCTION IF EXISTS fn_sync_gender();

-- ── Suppression des vues dépendantes ───────────────────────────────────────
DROP VIEW IF EXISTS v_patients_with_address;

-- ── Suppression de l'ancienne colonne et contrainte ────────────────────────
ALTER TABLE patients DROP CONSTRAINT IF EXISTS patients_gender_check;
ALTER TABLE patients DROP COLUMN gender;

-- ── Renommage gender_new → gender ──────────────────────────────────────────
ALTER TABLE patients RENAME COLUMN gender_new TO gender;

-- ── Recréation de la vue de compatibilité (Évolution A) ────────────────────
CREATE OR REPLACE VIEW v_patients_with_address AS
SELECT
    p.id, p.first_name, p.last_name, p.birth_date, p.gender, p.ssn,
    p.phone, p.email,
    a.line1 AS address_line1, a.line2 AS address_line2,
    a.city, a.postal_code, a.country
FROM patients p
LEFT JOIN addresses a ON a.patient_id = p.id AND a.is_primary = TRUE;
