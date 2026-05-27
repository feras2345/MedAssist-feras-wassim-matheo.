-- ==========================================================================
-- ROLLBACK V7 : Annulation Évolution B – CONTRACT
-- Restaure la colonne doctor_name depuis la table doctors
-- ==========================================================================

DROP VIEW IF EXISTS v_consultations_with_doctor;

ALTER TABLE consultations ADD COLUMN IF NOT EXISTS doctor_name VARCHAR(200);

UPDATE consultations c
SET doctor_name = 'Dr. ' || d.last_name
FROM doctors d
WHERE d.id = c.doctor_id;

ALTER TABLE consultations ALTER COLUMN doctor_name SET NOT NULL;
ALTER TABLE consultations ALTER COLUMN doctor_id DROP NOT NULL;
