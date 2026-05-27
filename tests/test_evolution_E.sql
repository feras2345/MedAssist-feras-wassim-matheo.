-- ==========================================================================
-- TESTS : Évolution E – Partitionnement consultations
-- Chaque bloc DO lève une EXCEPTION si le test échoue.
-- ==========================================================================

-- ── TEST E1 : La table consultations est partitionnée ──────────────────────
DO $$
DECLARE
    v_is_partitioned BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_partitioned_table pt
        JOIN pg_class c ON c.oid = pt.partrelid
        WHERE c.relname = 'consultations'
    ) INTO v_is_partitioned;

    IF NOT v_is_partitioned THEN
        RAISE EXCEPTION 'TEST E1 ÉCHOUÉ : consultations n''est pas partitionnée';
    END IF;
    RAISE NOTICE 'TEST E1 OK : consultations est partitionnée';
END $$;

-- ── TEST E2 : Partitions par année existent ────────────────────────────────
DO $$
DECLARE
    v_partitions INTEGER;
BEGIN
    SELECT count(*) INTO v_partitions
    FROM pg_inherits i
    JOIN pg_class parent ON parent.oid = i.inhparent
    JOIN pg_class child  ON child.oid  = i.inhrelid
    WHERE parent.relname = 'consultations';

    IF v_partitions < 5 THEN
        RAISE EXCEPTION 'TEST E2 ÉCHOUÉ : seulement % partitions (attendu >= 5)', v_partitions;
    END IF;
    RAISE NOTICE 'TEST E2 OK : % partitions trouvées', v_partitions;
END $$;

-- ── TEST E3 : Aucune perte de données après migration ──────────────────────
DO $$
DECLARE
    v_new_count INTEGER;
    v_old_count INTEGER;
BEGIN
    SELECT count(*) INTO v_new_count FROM consultations;

    -- L'ancienne table est conservée en backup
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consultations_old') THEN
        SELECT count(*) INTO v_old_count FROM consultations_old;
        IF v_new_count < v_old_count THEN
            RAISE EXCEPTION 'TEST E3 ÉCHOUÉ : perte de données ! ancien=% nouveau=%', v_old_count, v_new_count;
        END IF;
    END IF;

    IF v_new_count = 0 THEN
        RAISE EXCEPTION 'TEST E3 ÉCHOUÉ : table consultations vide après partitionnement';
    END IF;
    RAISE NOTICE 'TEST E3 OK : % consultations dans la table partitionnée (zéro perte)', v_new_count;
END $$;

-- ── TEST E4 : Insertion dans la bonne partition ────────────────────────────
DO $$
DECLARE
    v_partition TEXT;
BEGIN
    -- Vérifie que les données 2024 sont dans la partition 2024
    SELECT tableoid::regclass::text INTO v_partition
    FROM consultations
    WHERE consultation_date >= '2024-01-01' AND consultation_date < '2025-01-01'
    LIMIT 1;

    IF v_partition IS NULL THEN
        RAISE NOTICE 'TEST E4 SKIP : pas de données 2024';
    ELSIF v_partition NOT LIKE '%2024%' THEN
        RAISE EXCEPTION 'TEST E4 ÉCHOUÉ : données 2024 dans partition % (attendu: *2024*)', v_partition;
    ELSE
        RAISE NOTICE 'TEST E4 OK : données 2024 dans partition %', v_partition;
    END IF;
END $$;

-- ── TEST E5 : Intégrité référentielle prescriptions → consultations ───────
DO $$
DECLARE
    v_orphans INTEGER;
BEGIN
    SELECT count(*) INTO v_orphans
    FROM prescriptions p
    WHERE NOT EXISTS (SELECT 1 FROM consultations c WHERE c.id = p.consultation_id);

    IF v_orphans > 0 THEN
        RAISE EXCEPTION 'TEST E5 ÉCHOUÉ : % prescriptions orphelines', v_orphans;
    END IF;
    RAISE NOTICE 'TEST E5 OK : intégrité référentielle prescriptions→consultations';
END $$;

-- ── TEST E6 : Nouvelle insertion fonctionne ────────────────────────────────
DO $$
DECLARE
    v_id INTEGER;
BEGIN
    INSERT INTO consultations (patient_id, doctor_id, consultation_date, symptoms, diagnosis, consultation_type, fee_amount, is_paid)
    VALUES (1, 1, '2026-05-27 10:00', 'Test partitionnement', 'Test', 'test', 0, FALSE)
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'TEST E6 ÉCHOUÉ : insertion dans table partitionnée échouée';
    END IF;

    -- Nettoyage
    DELETE FROM consultations WHERE id = v_id;
    RAISE NOTICE 'TEST E6 OK : insertion/suppression dans table partitionnée (id=%)', v_id;
END $$;
