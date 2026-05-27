-- ==========================================================================
-- ROLLBACK V4 : Annulation Évolution A – CONTRACT
-- Restaure les colonnes adresse dans patients depuis la table addresses
-- ==========================================================================

DROP VIEW IF EXISTS v_patients_with_address;

ALTER TABLE patients ADD COLUMN IF NOT EXISTS address_line1 VARCHAR(255);
ALTER TABLE patients ADD COLUMN IF NOT EXISTS address_line2 VARCHAR(255);
ALTER TABLE patients ADD COLUMN IF NOT EXISTS city          VARCHAR(100);
ALTER TABLE patients ADD COLUMN IF NOT EXISTS postal_code   VARCHAR(10);

-- Restauration des données depuis addresses
UPDATE patients p
SET address_line1 = a.line1,
    address_line2 = a.line2,
    city          = a.city,
    postal_code   = a.postal_code
FROM addresses a
WHERE a.patient_id = p.id AND a.is_primary = TRUE;

-- Recréation du trigger de synchronisation
CREATE OR REPLACE FUNCTION fn_sync_patient_to_address()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        UPDATE addresses
        SET line1 = NEW.address_line1, line2 = NEW.address_line2,
            city = NEW.city, postal_code = NEW.postal_code, updated_at = now()
        WHERE patient_id = NEW.id AND is_primary = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_patient_address
    AFTER UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_sync_patient_to_address();
