-- ==========================================================================
-- V5 : Évolution B – EXPAND – Création table doctors
-- Stratégie : Expand-Contract (phase 1/3)
-- Risque : FAIBLE – ajout de structure uniquement
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Nouvelle table doctors ─────────────────────────────────────────────────
CREATE TABLE doctors (
    id           SERIAL       PRIMARY KEY,
    rpps_number  VARCHAR(11)  UNIQUE,
    first_name   VARCHAR(100),
    last_name    VARCHAR(100) NOT NULL,
    specialty    VARCHAR(100),
    email        VARCHAR(150),
    created_at   TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE INDEX idx_doctors_name ON doctors(last_name, first_name);

-- ── Ajout de la colonne doctor_id (nullable pendant la transition) ─────────
ALTER TABLE consultations ADD COLUMN doctor_id INTEGER REFERENCES doctors(id);

CREATE INDEX idx_consultations_doctor ON consultations(doctor_id);

-- ── Trigger dual-write : toute écriture dans doctor_name peuple doctor_id ──
CREATE OR REPLACE FUNCTION fn_sync_doctor_name_to_id()
RETURNS TRIGGER AS $$
DECLARE
    v_normalized TEXT;
    v_doctor_id  INTEGER;
BEGIN
    IF NEW.doctor_name IS NOT NULL AND NEW.doctor_id IS NULL THEN
        -- Normalisation : trim, lower, suppression du "dr." / "dr "
        v_normalized := trim(both from lower(NEW.doctor_name));
        v_normalized := regexp_replace(v_normalized, '^dr\.?\s*', '');
        v_normalized := initcap(v_normalized);

        SELECT id INTO v_doctor_id FROM doctors WHERE last_name = v_normalized LIMIT 1;

        IF v_doctor_id IS NULL THEN
            INSERT INTO doctors (last_name) VALUES (v_normalized) RETURNING id INTO v_doctor_id;
        END IF;

        NEW.doctor_id := v_doctor_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_doctor_name
    BEFORE INSERT OR UPDATE ON consultations
    FOR EACH ROW EXECUTE FUNCTION fn_sync_doctor_name_to_id();
