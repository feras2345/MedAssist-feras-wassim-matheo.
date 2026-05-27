-- ==========================================================================
-- V8 : Évolution C – EXPAND – Extension du champ gender
-- Stratégie : Expand-Contract (phase 1/3)
-- Risque : FAIBLE – ajout de colonne, aucune suppression
-- Downtime estimé : 0 seconde
-- ==========================================================================

-- ── Nouvelle colonne gender étendue ────────────────────────────────────────
-- CHAR(1) ne peut pas contenir 'NB' (2 caractères) → nouvelle colonne VARCHAR(2)
ALTER TABLE patients ADD COLUMN gender_new VARCHAR(2);

-- ── Contrainte CHECK pour les valeurs autorisées ───────────────────────────
ALTER TABLE patients ADD CONSTRAINT chk_gender_new
    CHECK (gender_new IN ('M', 'F', 'NB', 'U'));

-- ── Trigger dual-write : synchroniser gender → gender_new ──────────────────
CREATE OR REPLACE FUNCTION fn_sync_gender()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.gender IS NOT NULL AND NEW.gender_new IS NULL THEN
        NEW.gender_new := NEW.gender;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_gender
    BEFORE INSERT OR UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION fn_sync_gender();
