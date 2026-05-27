-- ==========================================================================
-- V6 : Évolution B – BACKFILL – Nettoyage doublons et peuplement doctor_id
-- Stratégie : Expand-Contract (phase 2/3)
-- Risque : MOYEN – nettoyage de données, vérification requise
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Étape 1 : Extraction et dédoublonnage des médecins ─────────────────────
-- Normalisation : suppression espaces, préfixe "dr.", mise en initcap
INSERT INTO doctors (last_name)
SELECT DISTINCT initcap(regexp_replace(trim(both from lower(doctor_name)), '^dr\.?\s*', ''))
FROM consultations
WHERE doctor_name IS NOT NULL
ON CONFLICT DO NOTHING;

-- ── Étape 2 : Peuplement de doctor_id dans consultations ───────────────────
UPDATE consultations c
SET doctor_id = d.id
FROM doctors d
WHERE d.last_name = initcap(regexp_replace(trim(both from lower(c.doctor_name)), '^dr\.?\s*', ''))
  AND c.doctor_id IS NULL;

-- ── Vérification post-backfill ─────────────────────────────────────────────
DO $$
DECLARE
    v_orphans INTEGER;
BEGIN
    SELECT count(*) INTO v_orphans
    FROM consultations
    WHERE doctor_id IS NULL;

    IF v_orphans > 0 THEN
        RAISE EXCEPTION 'BACKFILL B INCOMPLET : % consultations sans doctor_id', v_orphans;
    END IF;

    RAISE NOTICE 'Backfill B OK : tous les doctor_id peuplés';
END $$;
