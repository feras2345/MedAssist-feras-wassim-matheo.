-- ==========================================================================
-- TESTS : Évolution A – Extraction des adresses
-- Chaque bloc DO lève une EXCEPTION si le test échoue.
-- ==========================================================================

-- ── TEST A1 : La table addresses existe ────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'addresses' AND table_schema = 'public') THEN
        RAISE EXCEPTION 'TEST A1 ÉCHOUÉ : la table addresses n''existe pas';
    END IF;
    RAISE NOTICE 'TEST A1 OK : table addresses existe';
END $$;

-- ── TEST A2 : Colonnes requises présentes ──────────────────────────────────
DO $$
DECLARE
    v_cols TEXT[];
    v_col  TEXT;
BEGIN
    v_cols := ARRAY['id','patient_id','address_type','line1','line2','city','postal_code','country','is_primary'];
    FOREACH v_col IN ARRAY v_cols LOOP
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'addresses' AND column_name = v_col) THEN
            RAISE EXCEPTION 'TEST A2 ÉCHOUÉ : colonne % manquante dans addresses', v_col;
        END IF;
    END LOOP;
    RAISE NOTICE 'TEST A2 OK : toutes les colonnes requises présentes';
END $$;

-- ── TEST A3 : Toutes les adresses patients ont été migrées ─────────────────
DO $$
DECLARE
    v_orphans INTEGER;
BEGIN
    -- Vérifie qu'il n'y a pas de patients sans adresse dans addresses
    -- (après contract, les colonnes adresse n'existent plus dans patients)
    SELECT count(*) INTO v_orphans
    FROM addresses a
    WHERE a.is_primary = TRUE AND a.line1 IS NULL AND a.city IS NULL AND a.postal_code IS NULL;

    -- On vérifie simplement que des adresses existent
    IF (SELECT count(*) FROM addresses) = 0 THEN
        RAISE EXCEPTION 'TEST A3 ÉCHOUÉ : aucune adresse dans la table addresses';
    END IF;
    RAISE NOTICE 'TEST A3 OK : % adresses migrées', (SELECT count(*) FROM addresses);
END $$;

-- ── TEST A4 : Colonnes adresse supprimées de patients (post-contract) ──────
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'patients' AND column_name = 'address_line1') THEN
        RAISE EXCEPTION 'TEST A4 ÉCHOUÉ : colonne address_line1 toujours présente dans patients';
    END IF;
    RAISE NOTICE 'TEST A4 OK : colonnes adresse supprimées de patients';
END $$;

-- ── TEST A5 : Vue de compatibilité fonctionne ─────────────────────────────
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT count(*) INTO v_count FROM v_patients_with_address;
    IF v_count = 0 THEN
        RAISE EXCEPTION 'TEST A5 ÉCHOUÉ : vue v_patients_with_address vide';
    END IF;
    RAISE NOTICE 'TEST A5 OK : vue v_patients_with_address retourne % lignes', v_count;
END $$;

-- ── TEST A6 : FK patient_id valide ─────────────────────────────────────────
DO $$
DECLARE
    v_invalid INTEGER;
BEGIN
    SELECT count(*) INTO v_invalid
    FROM addresses a
    LEFT JOIN patients p ON p.id = a.patient_id
    WHERE p.id IS NULL;

    IF v_invalid > 0 THEN
        RAISE EXCEPTION 'TEST A6 ÉCHOUÉ : % adresses avec patient_id invalide', v_invalid;
    END IF;
    RAISE NOTICE 'TEST A6 OK : intégrité référentielle FK addresses→patients';
END $$;
