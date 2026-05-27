-- ==========================================================================
-- ROLLBACK V14 : Annulation Évolution E – EXPAND
-- ==========================================================================
DROP TRIGGER IF EXISTS trg_dual_write_consult ON consultations;
DROP FUNCTION IF EXISTS fn_dual_write_consultation();
DROP TABLE IF EXISTS consultations_default;
DROP TABLE IF EXISTS consultations_y2027;
DROP TABLE IF EXISTS consultations_y2026;
DROP TABLE IF EXISTS consultations_y2025;
DROP TABLE IF EXISTS consultations_y2024;
DROP TABLE IF EXISTS consultations_y2023;
DROP TABLE IF EXISTS consultations_partitioned;
