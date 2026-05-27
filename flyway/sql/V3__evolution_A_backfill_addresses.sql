-- ==========================================================================
-- V3 : Évolution A – BACKFILL – Migration des adresses existantes
-- Stratégie : Expand-Contract (phase 2/3)
-- Risque : FAIBLE – écriture seule, aucun verrou exclusif
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Migration des adresses existantes ──────────────────────────────────────
-- On insère uniquement les patients qui ont au moins un champ adresse renseigné
-- et qui ne sont pas déjà dans addresses (idempotent).
INSERT INTO addresses (patient_id, address_type, line1, line2, city, postal_code, country, is_primary)
SELECT p.id, 'domicile', p.address_line1, p.address_line2, p.city, p.postal_code, 'France', TRUE
FROM patients p
WHERE (p.address_line1 IS NOT NULL OR p.city IS NOT NULL OR p.postal_code IS NOT NULL)
  AND NOT EXISTS (
      SELECT 1 FROM addresses a WHERE a.patient_id = p.id AND a.is_primary = TRUE
  );

-- ── Vérification post-backfill ─────────────────────────────────────────────
DO $$
DECLARE
    v_patients_with_addr INTEGER;
    v_addresses_count    INTEGER;
BEGIN
    SELECT count(*) INTO v_patients_with_addr
    FROM patients
    WHERE address_line1 IS NOT NULL OR city IS NOT NULL OR postal_code IS NOT NULL;

    SELECT count(*) INTO v_addresses_count
    FROM addresses WHERE is_primary = TRUE;

    IF v_addresses_count < v_patients_with_addr THEN
        RAISE EXCEPTION 'BACKFILL INCOMPLET : % patients avec adresse mais seulement % entrées addresses',
            v_patients_with_addr, v_addresses_count;
    END IF;

    RAISE NOTICE 'Backfill A OK : % adresses migrées', v_addresses_count;
END $$;
