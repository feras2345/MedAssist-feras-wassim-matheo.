-- ==========================================================================
-- V16 : Évolution E – CONTRACT – Swap des tables consultations
-- Stratégie : Expand-Contract (phase 3/3)
-- Risque : ÉLEVÉ – renommage de tables, recréation des FK
-- Downtime estimé : < 5 secondes (verrous exclusifs brefs)
-- ==========================================================================

-- ── Suppression du trigger dual-write ──────────────────────────────────────
DROP TRIGGER IF EXISTS trg_dual_write_consult ON consultations;
DROP FUNCTION IF EXISTS fn_dual_write_consultation();

-- ── Suppression des FK référençant l'ancienne table ────────────────────────
ALTER TABLE prescriptions DROP CONSTRAINT IF EXISTS prescriptions_consultation_id_fkey;

-- ── Swap des tables ────────────────────────────────────────────────────────
ALTER TABLE consultations             RENAME TO consultations_old;
ALTER TABLE consultations_partitioned RENAME TO consultations;

-- ── Recréation de l'intégrité référentielle via trigger ────────────────────
-- PG16 : FK vers table partitionnée nécessite que la colonne référencée
-- fasse partie de la clé de partition. On utilise un trigger de validation.
CREATE OR REPLACE FUNCTION fn_check_consultation_fk()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM consultations WHERE id = NEW.consultation_id) THEN
        RAISE EXCEPTION 'Violation FK : consultation_id=% inexistant dans consultations', NEW.consultation_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prescriptions_fk_check
    BEFORE INSERT OR UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION fn_check_consultation_fk();

-- ── FK patients et doctors vers la table partitionnée ──────────────────────
-- Ces FK fonctionnent car patient_id et doctor_id ne sont pas la clé de partition
-- (la FK est dans le sens consultations → patients/doctors, pas l'inverse)

-- ── Nettoyage (optionnel, à exécuter après validation complète) ────────────
-- DROP TABLE IF EXISTS consultations_old;
-- On conserve l'ancienne table en backup temporaire

-- ── Vérification finale ────────────────────────────────────────────────────
DO $$
DECLARE
    v_is_partitioned BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_partitioned_table pt
        JOIN pg_class c ON c.oid = pt.partrelid
        WHERE c.relname = 'consultations'
    ) INTO v_is_partitioned;

    IF NOT v_is_partitioned THEN
        RAISE EXCEPTION 'CONTRACT E ECHOUE : la table consultations n''est pas partitionnée';
    END IF;

    RAISE NOTICE 'Contract E OK : consultations est maintenant partitionnée par année';
END $$;
