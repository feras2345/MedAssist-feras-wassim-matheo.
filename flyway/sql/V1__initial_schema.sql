-- ==========================================================================
-- V1 : Schéma initial – MedAssist
-- ==========================================================================

-- ── Table patients ─────────────────────────────────────────────────────────
CREATE TABLE patients (
    id             SERIAL       PRIMARY KEY,
    first_name     VARCHAR(100) NOT NULL,
    last_name      VARCHAR(100) NOT NULL,
    birth_date     DATE         NOT NULL,
    gender         CHAR(1)      CHECK (gender IN ('M','F')),
    ssn            VARCHAR(15)  NOT NULL UNIQUE,
    phone          VARCHAR(20),
    email          VARCHAR(150),
    address_line1  VARCHAR(255),
    address_line2  VARCHAR(255),
    city           VARCHAR(100),
    postal_code    VARCHAR(10),
    created_at     TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP    NOT NULL DEFAULT now()
);

-- ── Table consultations ────────────────────────────────────────────────────
CREATE TABLE consultations (
    id                 SERIAL        PRIMARY KEY,
    patient_id         INTEGER       NOT NULL REFERENCES patients(id),
    doctor_name        VARCHAR(200)  NOT NULL,
    consultation_date  TIMESTAMP     NOT NULL,
    symptoms           TEXT,
    diagnosis          TEXT,
    notes              TEXT,
    consultation_type  VARCHAR(50),
    fee_amount         DECIMAL(10,2),
    fee_currency       VARCHAR(3)    DEFAULT 'EUR',
    is_paid            BOOLEAN       DEFAULT FALSE,
    created_at         TIMESTAMP     NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP     NOT NULL DEFAULT now()
);

CREATE INDEX idx_consultations_patient  ON consultations(patient_id);
CREATE INDEX idx_consultations_date     ON consultations(consultation_date);

-- ── Table prescriptions ────────────────────────────────────────────────────
CREATE TABLE prescriptions (
    id               SERIAL       PRIMARY KEY,
    consultation_id  INTEGER      NOT NULL REFERENCES consultations(id),
    medication_name  VARCHAR(200) NOT NULL,
    dosage           VARCHAR(100),
    frequency        VARCHAR(100),
    duration_days    INTEGER,
    notes            TEXT,
    created_at       TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE INDEX idx_prescriptions_consultation ON prescriptions(consultation_id);

-- ── Données de démonstration ───────────────────────────────────────────────
INSERT INTO patients (first_name, last_name, birth_date, gender, ssn, phone, email, address_line1, city, postal_code)
VALUES
    ('Jean',   'Dupont',  '1985-03-15', 'M', '185031234567890', '0601020304', 'jean.dupont@mail.fr',   '12 rue de la Paix',       'Paris',     '75002'),
    ('Marie',  'Martin',  '1990-07-22', 'F', '290071234567891', '0611223344', 'marie.martin@mail.fr',  '5 avenue des Champs',     'Lyon',      '69001'),
    ('Pierre', 'Bernard', '1978-11-08', 'M', '178111234567892', '0622334455', 'pierre.b@mail.fr',      '8 boulevard Haussmann',   'Marseille', '13001'),
    ('Sophie', 'Leroy',   '2000-01-30', 'F', '200011234567893', '0633445566', 'sophie.leroy@mail.fr',  '22 place Bellecour',      'Lyon',      '69002'),
    ('Luc',    'Moreau',  '1965-05-12', 'M', '165051234567894', '0644556677', 'luc.moreau@mail.fr',    '3 impasse du Château',    'Bordeaux',  '33000');

INSERT INTO consultations (patient_id, doctor_name, consultation_date, symptoms, diagnosis, consultation_type, fee_amount, is_paid)
VALUES
    (1, 'Dr. Martin',      '2024-06-10 09:00', 'Fièvre, toux',        'Grippe saisonnière',      'generaliste', 25.00, TRUE),
    (1, 'Dr Martin',       '2024-09-15 14:30', 'Douleur dorsale',     'Lombalgie',               'generaliste', 25.00, TRUE),
    (2, 'Dr. Lefebvre',    '2024-07-20 10:00', 'Migraine',            'Céphalées de tension',    'neurologie',  50.00, FALSE),
    (3, 'Dr.Martin',       '2025-01-05 11:15', 'Toux persistante',    'Bronchite',               'generaliste', 25.00, TRUE),
    (4, 'Dr. Lefebvre',    '2025-03-12 16:00', 'Vertiges',            'Vertige positionnel',     'neurologie',  50.00, TRUE),
    (5, 'Dr. Dubois',      '2025-06-01 08:30', 'Douleur thoracique',  'Angine de poitrine',      'cardiologie', 60.00, FALSE),
    (2, 'dr. martin',      '2026-02-18 09:45', 'Fatigue chronique',   'Anémie ferriprive',       'generaliste', 25.00, TRUE),
    (3, ' Dr. Dubois ',    '2026-04-22 15:00', 'Essoufflement',       'Insuffisance cardiaque',  'cardiologie', 60.00, FALSE);

INSERT INTO prescriptions (consultation_id, medication_name, dosage, frequency, duration_days, notes)
VALUES
    (1, 'Paracétamol',  '1000mg', '3 fois/jour',  5,  'Après les repas'),
    (1, 'Amoxicilline', '500mg',  '2 fois/jour',  7,  NULL),
    (3, 'Ibuprofène',   '400mg',  '2 fois/jour',  10, 'Si douleur'),
    (4, 'Amoxicilline', '1g',     '3 fois/jour',  10, NULL),
    (6, 'Aspirine',     '100mg',  '1 fois/jour',  30, 'À vie si nécessaire'),
    (7, 'Fer Fumarate', '200mg',  '1 fois/jour',  90, 'À jeun');
