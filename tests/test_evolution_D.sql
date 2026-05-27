-- ==========================================================================
-- TESTS : Évolution D – Chiffrement SSN
-- Chaque bloc DO lève une EXCEPTION si le test échoue.
-- ==========================================================================

SET app.encryption_key = 'MedAssist-AES256-HDS-Key-2024!';

-- ── TEST D1 : Extension pgcrypto activée ───────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        RAISE EXCEPTION 'TEST D1 ÉCHOUÉ : extension pgcrypto non installée';
    END IF;
    RAISE NOTICE 'TEST D1 OK : pgcrypto activée';
END $$;

-- ── TEST D2 : Colonne ssn en clair supprimée ───────────────────────────────
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'patients' AND column_name = 'ssn' AND data_type = 'character varying') THEN
        RAISE EXCEPTION 'TEST D2 ÉCHOUÉ : colonne ssn en clair toujours présente';
    END IF;
    RAISE NOTICE 'TEST D2 OK : SSN en clair supprimé';
END $$;

-- ── TEST D3 : Colonnes chiffrées présentes et NOT NULL ─────────────────────
DO $$
DECLARE
    v_null_encrypted INTEGER;
    v_null_hash      INTEGER;
BEGIN
    SELECT count(*) INTO v_null_encrypted FROM patients WHERE ssn_encrypted IS NULL;
    SELECT count(*) INTO v_null_hash FROM patients WHERE ssn_hash IS NULL;

    IF v_null_encrypted > 0 THEN
        RAISE EXCEPTION 'TEST D3 ÉCHOUÉ : % patients avec ssn_encrypted NULL', v_null_encrypted;
    END IF;
    IF v_null_hash > 0 THEN
        RAISE EXCEPTION 'TEST D3 ÉCHOUÉ : % patients avec ssn_hash NULL', v_null_hash;
    END IF;
    RAISE NOTICE 'TEST D3 OK : toutes les colonnes chiffrées sont NOT NULL';
END $$;

-- ── TEST D4 : Déchiffrement fonctionne correctement ────────────────────────
DO $$
DECLARE
    v_decrypted TEXT;
BEGIN
    SELECT pgp_sym_decrypt(ssn_encrypted, current_setting('app.encryption_key'))
    INTO v_decrypted
    FROM patients LIMIT 1;

    IF v_decrypted IS NULL OR length(v_decrypted) = 0 THEN
        RAISE EXCEPTION 'TEST D4 ÉCHOUÉ : déchiffrement retourne NULL ou vide';
    END IF;

    -- Vérifier que le format SSN est valide (15 chiffres)
    IF v_decrypted !~ '^\d{15}$' THEN
        RAISE EXCEPTION 'TEST D4 ÉCHOUÉ : SSN déchiffré invalide: %', v_decrypted;
    END IF;
    RAISE NOTICE 'TEST D4 OK : déchiffrement correct, SSN = %', v_decrypted;
END $$;

-- ── TEST D5 : Unicité via ssn_hash ─────────────────────────────────────────
DO $$
DECLARE
    v_dupes INTEGER;
BEGIN
    SELECT count(*) - count(DISTINCT ssn_hash) INTO v_dupes FROM patients;
    IF v_dupes > 0 THEN
        RAISE EXCEPTION 'TEST D5 ÉCHOUÉ : % doublons de ssn_hash détectés', v_dupes;
    END IF;
    RAISE NOTICE 'TEST D5 OK : unicité SSN garantie via hash';
END $$;

-- ── TEST D6 : Index unique sur ssn_hash existe ─────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes WHERE tablename = 'patients' AND indexname = 'idx_patients_ssn_hash'
    ) THEN
        RAISE EXCEPTION 'TEST D6 ÉCHOUÉ : index unique idx_patients_ssn_hash manquant';
    END IF;
    RAISE NOTICE 'TEST D6 OK : index unique ssn_hash présent';
END $$;
