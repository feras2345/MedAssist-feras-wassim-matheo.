-- ==========================================================================
-- ROLLBACK V13 : Annulation Évolution D – CONTRACT
-- Restaure le SSN en clair depuis les données chiffrées
-- ==========================================================================

-- Recréer la colonne SSN en clair
ALTER TABLE patients ADD COLUMN ssn VARCHAR(15);

-- Déchiffrer et restaurer
SET app.encryption_key = 'MedAssist-AES256-HDS-Key-2024!';

UPDATE patients
SET ssn = pgp_sym_decrypt(ssn_encrypted, current_setting('app.encryption_key'))
WHERE ssn_encrypted IS NOT NULL;

ALTER TABLE patients ALTER COLUMN ssn SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS patients_ssn_key ON patients(ssn);

-- Remettre le trigger dual-write
CREATE OR REPLACE FUNCTION fn_sync_ssn_encrypt()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ssn IS NOT NULL AND NEW.ssn_encrypted IS NULL THEN
        NEW.ssn_encrypted := pgp_sym_encrypt(NEW.ssn, current_setting('app.encryption_key', true));
        NEW.ssn_hash := encode(digest(NEW.ssn, 'sha256'), 'hex');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_ssn_encrypt
    BEFORE INSERT OR UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_sync_ssn_encrypt();

-- Supprimer la fonction de déchiffrement du contract
DROP FUNCTION IF EXISTS fn_decrypt_ssn(BYTEA, TEXT);

-- Remettre les contraintes
ALTER TABLE patients ALTER COLUMN ssn_encrypted DROP NOT NULL;
ALTER TABLE patients ALTER COLUMN ssn_hash DROP NOT NULL;
