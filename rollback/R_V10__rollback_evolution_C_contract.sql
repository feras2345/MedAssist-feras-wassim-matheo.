-- ==========================================================================
-- ROLLBACK V10 : Annulation Évolution C – CONTRACT
-- Restaure l'ancien champ gender CHAR(1)
-- ==========================================================================

-- Le champ actuel s'appelle gender (ex gender_new VARCHAR(2))
ALTER TABLE patients RENAME COLUMN gender TO gender_new;

ALTER TABLE patients ADD COLUMN gender CHAR(1);
ALTER TABLE patients ADD CONSTRAINT patients_gender_check CHECK (gender IN ('M','F'));

UPDATE patients SET gender = gender_new WHERE gender_new IN ('M','F');
