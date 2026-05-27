-- ==========================================================================
-- V4 : Évolution A – CONTRACT – Suppression colonnes adresse de patients
-- Stratégie : Expand-Contract (phase 3/3)
-- Risque : MOYEN – suppression de colonnes (irréversible sans rollback)
-- Downtime estimé : < 1 seconde (ALTER TABLE, verrou bref)
-- ==========================================================================

-- ── Suppression du trigger de synchronisation ──────────────────────────────
DROP TRIGGER IF EXISTS trg_sync_patient_address ON patients;
DROP FUNCTION IF EXISTS fn_sync_patient_to_address();

-- ── Suppression des anciennes colonnes ─────────────────────────────────────
ALTER TABLE patients DROP COLUMN IF EXISTS address_line1;
ALTER TABLE patients DROP COLUMN IF EXISTS address_line2;
ALTER TABLE patients DROP COLUMN IF EXISTS city;
ALTER TABLE patients DROP COLUMN IF EXISTS postal_code;

-- ── Vue de commodité pour compatibilité applicative ────────────────────────
CREATE OR REPLACE VIEW v_patients_with_address AS
SELECT
    p.id, p.first_name, p.last_name, p.birth_date, p.gender, p.ssn,
    p.phone, p.email,
    a.line1 AS address_line1, a.line2 AS address_line2,
    a.city, a.postal_code, a.country
FROM patients p
LEFT JOIN addresses a ON a.patient_id = p.id AND a.is_primary = TRUE;
