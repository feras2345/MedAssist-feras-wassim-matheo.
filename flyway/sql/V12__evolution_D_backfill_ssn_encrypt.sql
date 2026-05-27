-- ==========================================================================
-- V12 : Évolution D – BACKFILL – Chiffrement des SSN existants
-- Stratégie : Expand-Contract (phase 2/3)
-- Risque : MOYEN – traitement cryptographique sur toutes les lignes
-- Downtime estimé : 0 seconde (traitement par lots possible)
-- ==========================================================================

-- ── Configuration de la clé de chiffrement ─────────────────────────────────
-- En production, cette valeur vient d'un vault ou d'une variable d'environnement.
SET app.encryption_key = 'MedAssist-AES256-HDS-Key-2024!';

-- ── Chiffrement par lots ───────────────────────────────────────────────────
UPDATE patients
SET ssn_encrypted = pgp_sym_encrypt(ssn, current_setting('app.encryption_key')),
    ssn_hash      = encode(digest(ssn, 'sha256'), 'hex')
WHERE ssn IS NOT NULL
  AND ssn_encrypted IS NULL;

-- ── Vérification post-backfill ─────────────────────────────────────────────
DO $$
DECLARE
    v_total      INTEGER;
    v_encrypted  INTEGER;
    v_decrypted  TEXT;
    v_original   TEXT;
BEGIN
    SELECT count(*) INTO v_total FROM patients WHERE ssn IS NOT NULL;
    SELECT count(*) INTO v_encrypted FROM patients WHERE ssn_encrypted IS NOT NULL;

    IF v_encrypted < v_total THEN
        RAISE EXCEPTION 'BACKFILL D INCOMPLET : % SSN non chiffrés sur %', (v_total - v_encrypted), v_total;
    END IF;

    -- Test de déchiffrement sur la première ligne
    SELECT ssn, pgp_sym_decrypt(ssn_encrypted, current_setting('app.encryption_key'))
    INTO v_original, v_decrypted
    FROM patients
    WHERE ssn IS NOT NULL LIMIT 1;

    IF v_original <> v_decrypted THEN
        RAISE EXCEPTION 'ERREUR DECHIFFREMENT : original=% vs déchiffré=%', v_original, v_decrypted;
    END IF;

    RAISE NOTICE 'Backfill D OK : % SSN chiffrés et vérifiés', v_encrypted;
END $$;
