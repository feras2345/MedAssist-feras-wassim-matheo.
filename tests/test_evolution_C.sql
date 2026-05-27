-- ==========================================================================
-- TESTS : Évolution C – Extension du champ gender
-- Chaque bloc DO lève une EXCEPTION si le test échoue.
-- ==========================================================================

-- ── TEST C1 : La colonne gender accepte VARCHAR(2) ─────────────────────────
DO $$
DECLARE
    v_type TEXT;
BEGIN
    SELECT data_type INTO v_type
    FROM information_schema.columns
    WHERE table_name = 'patients' AND column_name = 'gender';

    IF v_type NOT IN ('character varying', 'character') THEN
        RAISE EXCEPTION 'TEST C1 ÉCHOUÉ : gender est de type % (attendu: character varying)', v_type;
    END IF;
    RAISE NOTICE 'TEST C1 OK : gender est de type %', v_type;
END $$;

-- ── TEST C2 : Les valeurs M, F, NB, U sont acceptées ──────────────────────
DO $$
BEGIN
    -- Test d'insertion avec chaque valeur autorisée
    INSERT INTO patients (first_name, last_name, birth_date, gender, ssn)
    VALUES ('Test_NB', 'Gender_NB', '2000-01-01', 'NB', '100001234567890');

    INSERT INTO patients (first_name, last_name, birth_date, gender, ssn)
    VALUES ('Test_U', 'Gender_U', '2000-01-01', 'U', '100001234567891');

    -- Nettoyage
    DELETE FROM patients WHERE first_name IN ('Test_NB', 'Test_U');

    RAISE NOTICE 'TEST C2 OK : valeurs NB et U acceptées';
EXCEPTION WHEN check_violation THEN
    RAISE EXCEPTION 'TEST C2 ÉCHOUÉ : CHECK constraint rejette NB ou U';
END $$;

-- ── TEST C3 : Les valeurs invalides sont rejetées ──────────────────────────
DO $$
BEGIN
    BEGIN
        INSERT INTO patients (first_name, last_name, birth_date, gender, ssn)
        VALUES ('Test_X', 'Gender_X', '2000-01-01', 'X', '100001234567892');
        -- Si on arrive ici, le CHECK ne fonctionne pas
        DELETE FROM patients WHERE first_name = 'Test_X';
        RAISE EXCEPTION 'TEST C3 ÉCHOUÉ : valeur X acceptée (devrait être rejetée)';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'TEST C3 OK : valeur invalide X correctement rejetée';
    END;
END $$;

-- ── TEST C4 : Données existantes préservées ────────────────────────────────
DO $$
DECLARE
    v_null_genders INTEGER;
    v_total        INTEGER;
BEGIN
    SELECT count(*) INTO v_total FROM patients WHERE first_name NOT LIKE 'Test_%';
    SELECT count(*) INTO v_null_genders FROM patients WHERE gender IS NULL AND first_name NOT LIKE 'Test_%';

    IF v_null_genders = v_total THEN
        RAISE EXCEPTION 'TEST C4 ÉCHOUÉ : tous les genders sont NULL après migration';
    END IF;
    RAISE NOTICE 'TEST C4 OK : % patients avec gender renseigné', (v_total - v_null_genders);
END $$;
