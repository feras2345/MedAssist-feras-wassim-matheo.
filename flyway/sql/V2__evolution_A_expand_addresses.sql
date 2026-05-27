-- ==========================================================================
-- V2 : Évolution A – EXPAND – Extraction des adresses
-- Stratégie : Expand-Contract (phase 1/3)
-- Risque : FAIBLE – ajout de structure, aucune suppression
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Nouvelle table addresses ───────────────────────────────────────────────
CREATE TABLE addresses (
    id           SERIAL       PRIMARY KEY,
    patient_id   INTEGER      NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    address_type VARCHAR(20)  NOT NULL DEFAULT 'domicile',
    line1        VARCHAR(255),
    line2        VARCHAR(255),
    city         VARCHAR(100),
    postal_code  VARCHAR(10),
    country      VARCHAR(100) NOT NULL DEFAULT 'France',
    is_primary   BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE INDEX idx_addresses_patient   ON addresses(patient_id);
CREATE INDEX idx_addresses_primary   ON addresses(patient_id) WHERE is_primary = TRUE;

-- ── Trigger de synchronisation patients → addresses (dual-write) ───────────
-- Toute modification des colonnes adresse dans patients est répliquée
-- dans la nouvelle table addresses pour maintenir la compatibilité.
CREATE OR REPLACE FUNCTION fn_sync_patient_to_address()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.address_line1 IS NOT NULL OR NEW.city IS NOT NULL THEN
            INSERT INTO addresses (patient_id, address_type, line1, line2, city, postal_code, is_primary)
            VALUES (NEW.id, 'domicile', NEW.address_line1, NEW.address_line2, NEW.city, NEW.postal_code, TRUE)
            ON CONFLICT DO NOTHING;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.address_line1 IS DISTINCT FROM OLD.address_line1
           OR NEW.address_line2 IS DISTINCT FROM OLD.address_line2
           OR NEW.city IS DISTINCT FROM OLD.city
           OR NEW.postal_code IS DISTINCT FROM OLD.postal_code THEN
            UPDATE addresses
            SET line1 = NEW.address_line1,
                line2 = NEW.address_line2,
                city  = NEW.city,
                postal_code = NEW.postal_code,
                updated_at  = now()
            WHERE patient_id = NEW.id AND is_primary = TRUE;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_patient_address
    AFTER INSERT OR UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_sync_patient_to_address();
