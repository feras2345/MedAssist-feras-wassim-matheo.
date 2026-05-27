-- ==========================================================================
-- ROLLBACK V16 : Annulation Évolution E – CONTRACT
-- Restaure la table consultations non-partitionnée
-- ==========================================================================

-- Supprimer le trigger FK
DROP TRIGGER IF EXISTS trg_prescriptions_fk_check ON prescriptions;
DROP FUNCTION IF EXISTS fn_check_consultation_fk();

-- Swap inverse
ALTER TABLE consultations     RENAME TO consultations_partitioned;
ALTER TABLE consultations_old RENAME TO consultations;

-- Restaurer la FK native de prescriptions
ALTER TABLE prescriptions ADD CONSTRAINT prescriptions_consultation_id_fkey
    FOREIGN KEY (consultation_id) REFERENCES consultations(id);

-- Restaurer le trigger dual-write (état expand)
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
    ON CONFLICT (id, consultation_date) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dual_write_consult
    AFTER INSERT OR UPDATE ON consultations
    FOR EACH ROW EXECUTE FUNCTION fn_dual_write_consultation();
