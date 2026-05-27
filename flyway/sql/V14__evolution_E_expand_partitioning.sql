-- ==========================================================================
-- V14 : Évolution E – EXPAND – Partitionnement consultations par année
-- Stratégie : Expand-Contract (phase 1/3)
-- Risque : MOYEN – création de table partitionnée parallèle
-- Downtime estimé : 0 seconde
-- Note PG16 : impossible de convertir une table existante en partitionnée,
--             on crée une nouvelle table et on migre les données.
-- ==========================================================================

-- ── Nouvelle table partitionnée ────────────────────────────────────────────
CREATE TABLE consultations_partitioned (
    id                 SERIAL,
    patient_id         INTEGER       NOT NULL,
    doctor_id          INTEGER       NOT NULL,
    consultation_date  TIMESTAMP     NOT NULL,
    symptoms           TEXT,
    diagnosis          TEXT,
    notes              TEXT,
    consultation_type  VARCHAR(50),
    fee_amount         DECIMAL(10,2),
    fee_currency       VARCHAR(3)    DEFAULT 'EUR',
    is_paid            BOOLEAN       DEFAULT FALSE,
    created_at         TIMESTAMP     NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP     NOT NULL DEFAULT now(),
    PRIMARY KEY (id, consultation_date)
) PARTITION BY RANGE (consultation_date);

-- ── Création des partitions par année ──────────────────────────────────────
CREATE TABLE consultations_y2023 PARTITION OF consultations_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE consultations_y2024 PARTITION OF consultations_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE consultations_y2025 PARTITION OF consultations_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE consultations_y2026 PARTITION OF consultations_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE consultations_y2027 PARTITION OF consultations_partitioned
    FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

CREATE TABLE consultations_default PARTITION OF consultations_partitioned
    DEFAULT;

-- ── Index sur la table partitionnée ────────────────────────────────────────
CREATE INDEX idx_cp_patient ON consultations_partitioned(patient_id);
CREATE INDEX idx_cp_doctor  ON consultations_partitioned(doctor_id);
CREATE INDEX idx_cp_date    ON consultations_partitioned(consultation_date);

-- ── Trigger dual-write : réplique les INSERT dans la nouvelle table ────────
CREATE OR REPLACE FUNCTION fn_dual_write_consultation()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO consultations_partitioned
        (id, patient_id, doctor_id, consultation_date, symptoms, diagnosis,
         notes, consultation_type, fee_amount, fee_currency, is_paid, created_at, updated_at)
    VALUES
        (NEW.id, NEW.patient_id, NEW.doctor_id, NEW.consultation_date, NEW.symptoms,
         NEW.diagnosis, NEW.notes, NEW.consultation_type, NEW.fee_amount,
         NEW.fee_currency, NEW.is_paid, NEW.created_at, NEW.updated_at)
    ON CONFLICT (id, consultation_date) DO UPDATE SET
        patient_id = EXCLUDED.patient_id,
        doctor_id  = EXCLUDED.doctor_id,
        symptoms   = EXCLUDED.symptoms,
        diagnosis  = EXCLUDED.diagnosis,
        notes      = EXCLUDED.notes,
        consultation_type = EXCLUDED.consultation_type,
        fee_amount   = EXCLUDED.fee_amount,
        fee_currency = EXCLUDED.fee_currency,
        is_paid      = EXCLUDED.is_paid,
        updated_at   = EXCLUDED.updated_at;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dual_write_consult
    AFTER INSERT OR UPDATE ON consultations
    FOR EACH ROW EXECUTE FUNCTION fn_dual_write_consultation();
