-- ==========================================================================
-- V9 : Évolution C – BACKFILL – Copie des valeurs gender existantes
-- Stratégie : Expand-Contract (phase 2/3)
-- Risque : FAIBLE – mise à jour de données existantes
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Copie gender → gender_new ──────────────────────────────────────────────
UPDATE patients
SET gender_new = gender
WHERE gender IS NOT NULL AND gender_new IS NULL;

-- ── Vérification post-backfill ─────────────────────────────────────────────
DO $$
DECLARE
    v_mismatch INTEGER;
BEGIN
    SELECT count(*) INTO v_mismatch
    FROM patients
    WHERE gender IS NOT NULL AND gender_new IS NULL;

    IF v_mismatch > 0 THEN
        RAISE EXCEPTION 'BACKFILL C INCOMPLET : % patients avec gender mais sans gender_new', v_mismatch;
    END IF;

    RAISE NOTICE 'Backfill C OK : toutes les valeurs gender migrées vers gender_new';
END $$;
