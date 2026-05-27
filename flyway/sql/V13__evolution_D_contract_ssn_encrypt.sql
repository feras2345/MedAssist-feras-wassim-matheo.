-- ==========================================================================
-- V13 : Évolution D – CONTRACT – Suppression du SSN en clair
-- Stratégie : Expand-Contract (phase 3/3)
-- Risque : ÉLEVÉ – suppression définitive des données en clair
-- Downtime estimé : < 1 seconde
-- Conformité : RGPD Art. 32 – minimisation des données sensibles
-- ==========================================================================

-- ── Suppression du trigger dual-write ──────────────────────────────────────
DROP TRIGGER IF EXISTS trg_sync_ssn_encrypt ON patients;
DROP FUNCTION IF EXISTS fn_sync_ssn_encrypt();

-- ── Suppression de l'ancien index unique sur ssn clair ─────────────────────
ALTER TABLE patients DROP CONSTRAINT IF EXISTS patients_ssn_key;

-- ── Suppression des vues dépendantes ───────────────────────────────────────
DROP VIEW IF EXISTS v_patients_with_address;

-- ── Suppression de la colonne SSN en clair ─────────────────────────────────
ALTER TABLE patients DROP COLUMN ssn;

-- ── Contrainte NOT NULL sur la colonne chiffrée ────────────────────────────
ALTER TABLE patients ALTER COLUMN ssn_encrypted SET NOT NULL;
ALTER TABLE patients ALTER COLUMN ssn_hash SET NOT NULL;

-- ── Recréation de la vue de compatibilité (sans SSN en clair) ──────────────
CREATE OR REPLACE VIEW v_patients_with_address AS
SELECT
    p.id, p.first_name, p.last_name, p.birth_date, p.gender,
    p.ssn_hash, p.phone, p.email,
    a.line1 AS address_line1, a.line2 AS address_line2,
    a.city, a.postal_code, a.country
FROM patients p
LEFT JOIN addresses a ON a.patient_id = p.id AND a.is_primary = TRUE;

-- ── Fonction utilitaire de déchiffrement ───────────────────────────────────
CREATE OR REPLACE FUNCTION fn_decrypt_ssn(p_encrypted BYTEA, p_key TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN pgp_sym_decrypt(p_encrypted, p_key);
EXCEPTION WHEN OTHERS THEN
    RETURN '[ERREUR DECHIFFREMENT]';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Restreindre l'accès à la fonction de déchiffrement
REVOKE ALL ON FUNCTION fn_decrypt_ssn(BYTEA, TEXT) FROM PUBLIC;
