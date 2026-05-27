-- ==========================================================================
-- TESTS : Évolution B – Création table doctors
-- Chaque bloc DO lève une EXCEPTION si le test échoue.
-- ==========================================================================

-- ── TEST B1 : La table doctors existe ──────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'doctors' AND table_schema = 'public') THEN
        RAISE EXCEPTION 'TEST B1 ÉCHOUÉ : la table doctors n''existe pas';
    END IF;
    RAISE NOTICE 'TEST B1 OK : table doctors existe';
END $$;

-- ── TEST B2 : Colonnes requises dans doctors ───────────────────────────────
DO $$
DECLARE
    v_cols TEXT[];
    v_col  TEXT;
BEGIN
    v_cols := ARRAY['id','rpps_number','first_name','last_name','specialty','email'];
    FOREACH v_col IN ARRAY v_cols LOOP
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'doctors' AND column_name = v_col) THEN
            RAISE EXCEPTION 'TEST B2 ÉCHOUÉ : colonne % manquante dans doctors', v_col;
        END IF;
    END LOOP;
    RAISE NOTICE 'TEST B2 OK : toutes les colonnes requises présentes';
END $$;

-- ── TEST B3 : Pas de doublons dans doctors ─────────────────────────────────
DO $$
DECLARE
    v_dupes INTEGER;
BEGIN
    SELECT count(*) - count(DISTINCT last_name) INTO v_dupes FROM doctors;
    IF v_dupes > 0 THEN
        RAISE EXCEPTION 'TEST B3 ÉCHOUÉ : % doublons de last_name dans doctors', v_dupes;
    END IF;
    RAISE NOTICE 'TEST B3 OK : aucun doublon dans doctors (% médecins)', (SELECT count(*) FROM doctors);
END $$;

-- ── TEST B4 : Toutes les consultations ont un doctor_id ────────────────────
DO $$
DECLARE
    v_nulls INTEGER;
BEGIN
    SELECT count(*) INTO v_nulls FROM consultations WHERE doctor_id IS NULL;
    IF v_nulls > 0 THEN
        RAISE EXCEPTION 'TEST B4 ÉCHOUÉ : % consultations sans doctor_id', v_nulls;
    END IF;
    RAISE NOTICE 'TEST B4 OK : toutes les consultations ont un doctor_id';
END $$;

-- ── TEST B5 : Colonne doctor_name supprimée (post-contract) ────────────────
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'consultations' AND column_name = 'doctor_name') THEN
        RAISE EXCEPTION 'TEST B5 ÉCHOUÉ : colonne doctor_name toujours présente';
    END IF;
    RAISE NOTICE 'TEST B5 OK : colonne doctor_name supprimée';
END $$;

-- ── TEST B6 : FK doctor_id valide ──────────────────────────────────────────
DO $$
DECLARE
    v_invalid INTEGER;
BEGIN
    SELECT count(*) INTO v_invalid
    FROM consultations c
    LEFT JOIN doctors d ON d.id = c.doctor_id
    WHERE d.id IS NULL;

    IF v_invalid > 0 THEN
        RAISE EXCEPTION 'TEST B6 ÉCHOUÉ : % consultations avec doctor_id invalide', v_invalid;
    END IF;
    RAISE NOTICE 'TEST B6 OK : intégrité référentielle FK consultations→doctors';
END $$;

-- ── TEST B7 : Dédoublonnage correct (Dr. Martin / dr. martin / Dr.Martin) ─
DO $$
DECLARE
    v_martin_count INTEGER;
BEGIN
    SELECT count(*) INTO v_martin_count FROM doctors WHERE lower(last_name) = 'martin';
    IF v_martin_count > 1 THEN
        RAISE EXCEPTION 'TEST B7 ÉCHOUÉ : % entrées pour Martin (attendu: 1)', v_martin_count;
    END IF;
    RAISE NOTICE 'TEST B7 OK : dédoublonnage correct pour Martin';
END $$;
