-- ==========================================================================
-- V15 : Évolution E – BACKFILL – Migration des consultations existantes
-- Stratégie : Expand-Contract (phase 2/3)
-- Risque : MOYEN – copie de données volumineuse
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Copie des données existantes ───────────────────────────────────────────
INSERT INTO consultations_partitioned
    (id, patient_id, doctor_id, consultation_date, symptoms, diagnosis,
     notes, consultation_type, fee_amount, fee_currency, is_paid, created_at, updated_at)
SELECT
    id, patient_id, doctor_id, consultation_date, symptoms, diagnosis,
    notes, consultation_type, fee_amount, fee_currency, is_paid, created_at, updated_at
FROM consultations
ON CONFLICT (id, consultation_date) DO NOTHING;

-- ── Synchronisation de la séquence ─────────────────────────────────────────
SELECT setval(
    pg_get_serial_sequence('consultations_partitioned', 'id'),
    GREATEST(
        (SELECT max(id) FROM consultations),
        (SELECT max(id) FROM consultations_partitioned)
    )
);

-- ── Vérification post-backfill ─────────────────────────────────────────────
DO $$
DECLARE
    v_old_count  INTEGER;
    v_new_count  INTEGER;
BEGIN
    SELECT count(*) INTO v_old_count FROM consultations;
    SELECT count(*) INTO v_new_count FROM consultations_partitioned;

    IF v_new_count < v_old_count THEN
        RAISE EXCEPTION 'BACKFILL E INCOMPLET : % lignes anciennes vs % partitionnées',
            v_old_count, v_new_count;
    END IF;

    RAISE NOTICE 'Backfill E OK : % consultations migrées vers table partitionnée', v_new_count;
END $$;
