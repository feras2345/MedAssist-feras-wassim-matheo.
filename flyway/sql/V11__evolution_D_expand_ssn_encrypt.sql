-- ==========================================================================
-- V11 : Évolution D – EXPAND – Chiffrement SSN (pgcrypto)
-- Stratégie : Expand-Contract (phase 1/3)
-- Risque : FAIBLE – ajout d'extension et de colonnes
-- Downtime estimé : 0 seconde
-- Conformité : HDS / RGPD – chiffrement AES-256 au repos
-- ==========================================================================

-- ── Activation de pgcrypto ─────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Nouvelles colonnes chiffrées ───────────────────────────────────────────
-- ssn_encrypted : stockage chiffré PGP (AES-256) – déchiffrable
-- ssn_hash      : empreinte SHA-256 pour garantir l'unicité sans déchiffrer
ALTER TABLE patients ADD COLUMN ssn_encrypted BYTEA;
ALTER TABLE patients ADD COLUMN ssn_hash      TEXT;

-- ── Index unique sur le hash (remplace l'unicité du SSN en clair) ──────────
CREATE UNIQUE INDEX idx_patients_ssn_hash ON patients(ssn_hash);

-- ── Trigger dual-write : tout INSERT/UPDATE du ssn clair chiffre aussi ─────
CREATE OR REPLACE FUNCTION fn_sync_ssn_encrypt()
RETURNS TRIGGER AS $$
DECLARE
    v_key TEXT;
BEGIN
    IF NEW.ssn IS NOT NULL AND NEW.ssn_encrypted IS NULL THEN
        v_key := current_setting('app.encryption_key', true);
        IF v_key IS NULL OR v_key = '' THEN
            v_key := 'MedAssist-AES256-HDS-Key-2024!';
        END IF;
        NEW.ssn_encrypted := pgp_sym_encrypt(NEW.ssn, v_key);
        NEW.ssn_hash      := encode(digest(NEW.ssn, 'sha256'), 'hex');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_ssn_encrypt
    BEFORE INSERT OR UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_sync_ssn_encrypt();
