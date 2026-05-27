-- ==========================================================================
-- V7 : Évolution B – CONTRACT – Suppression doctor_name
-- Stratégie : Expand-Contract (phase 3/3)
-- Risque : MOYEN – suppression de colonne
-- Downtime estimé : < 1 seconde
-- ==========================================================================

-- ── Suppression du trigger dual-write ──────────────────────────────────────
DROP TRIGGER IF EXISTS trg_sync_doctor_name ON consultations;
DROP FUNCTION IF EXISTS fn_sync_doctor_name_to_id();

-- ── Contrainte NOT NULL sur doctor_id ──────────────────────────────────────
ALTER TABLE consultations ALTER COLUMN doctor_id SET NOT NULL;

-- ── Suppression de l'ancienne colonne ──────────────────────────────────────
ALTER TABLE consultations DROP COLUMN IF EXISTS doctor_name;

-- ── Vue de commodité ───────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_consultations_with_doctor AS
SELECT
    c.id, c.patient_id, c.consultation_date,
    d.first_name AS doctor_first_name,
    d.last_name  AS doctor_last_name,
    d.rpps_number,
    d.specialty,
    c.symptoms, c.diagnosis, c.notes,
    c.consultation_type, c.fee_amount, c.fee_currency, c.is_paid
FROM consultations c
JOIN doctors d ON d.id = c.doctor_id;
