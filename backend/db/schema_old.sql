-- ============================================================================
-- PROJET : GESTION ET SUIVI DE DISTRIBUTION DE TIMBRES & VALEURS INACTIVES
-- FICHIER : backend/db/schema.sql
-- DESCRIPTION : Définition des structures relationnelles, contraintes et index.
-- ============================================================================

-- Suppression en cascade pour repartir sur un environnement propre lors des tests
DROP TABLE IF EXISTS session_agent_detail CASCADE;
DROP TABLE IF EXISTS session_agent CASCADE;
DROP TABLE IF EXISTS mouvement_stock_central CASCADE;
DROP TABLE IF EXISTS type_valeur CASCADE;
DROP TABLE IF EXISTS agent CASCADE;

-- ----------------------------------------------------------------------------
-- 1. TABLE : agent
-- RÔLE : Enregistre l'ensemble des agents distributeurs / promoteurs habilités.
-- JUSTIFICATION : Permet d'identifier individuellement le responsable d'une
-- sacoche de timbres et d'imputer les recettes perçues.
-- ----------------------------------------------------------------------------
CREATE TABLE agent (
    id SERIAL PRIMARY KEY,
    matricule VARCHAR(30) UNIQUE NOT NULL,      -- Ex: 'AGT-2026-001' (identifiant métier unique)
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    telephone VARCHAR(30),
    statut VARCHAR(20) DEFAULT 'ACTIF' 
        CHECK (statut IN ('ACTIF', 'SUSPENDU')), -- Un agent suspendu ne peut pas retirer de stock
    date_creation TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 2. TABLE : type_valeur
-- RÔLE : Référentiel des coupures de timbres fiscaux et valeurs inactives.
-- JUSTIFICATION : Évite la redondance textuelle et garantit l'exactitude
-- des calculs de recettes (100F, 500F, 1000F).
-- ----------------------------------------------------------------------------
CREATE TABLE type_valeur (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) UNIQUE NOT NULL,           -- Code unique machine (ex: 'TMB_100')
    libelle VARCHAR(100) NOT NULL,              -- Libellé lisible (ex: 'Timbre Fiscal 100 F')
    valeur_nominale NUMERIC(10, 2) NOT NULL 
        CHECK (valeur_nominale > 0),            -- Type NUMERIC pour la précision monétaire exacte
    categorie VARCHAR(50) DEFAULT 'Timbre'      -- Prévu pour extensions : Ticket, Acte, Quittance
);

-- ----------------------------------------------------------------------------
-- 3. TABLE : mouvement_stock_central
-- RÔLE : Grand Livre d'Inventaire Central.
-- JUSTIFICATION : Modélise l'historique immuable des flux du magasin.
-- Le solde réel n'est jamais écrasé, il découle de la somme des entrées/sorties.
-- ----------------------------------------------------------------------------
CREATE TABLE mouvement_stock_central (
    id SERIAL PRIMARY KEY,
    reference_mvt VARCHAR(60) UNIQUE NOT NULL,  -- Identifiant unique du bordereau de mouvement
    date_mouvement TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    id_valeur INT NOT NULL 
        REFERENCES type_valeur(id) 
        ON DELETE RESTRICT,                     -- Empêche la suppression d'un timbre déjà mouvementé
    type_mouvement VARCHAR(10) NOT NULL 
        CHECK (type_mouvement IN ('ENTREE', 'SORTIE')), -- ENTREE = fournisseur, SORTIE = agent
    quantite INT NOT NULL 
        CHECK (quantite > 0),                   -- Mouvement toujours strictement positif
    id_agent INT 
        REFERENCES agent(id) 
        ON DELETE SET NULL,                     -- Null si livraison fournisseur ; renseigné si remise agent
    motif VARCHAR(255) NOT NULL                 -- Justification (ex: 'Dotation matin', 'Livraison régie')
);

-- Index pour accélérer le calcul dynamique du solde par coupure
CREATE INDEX idx_mvt_stock_valeur ON mouvement_stock_central(id_valeur);

-- ----------------------------------------------------------------------------
-- 4. TABLE : session_agent
-- RÔLE : Enveloppe journalière de mission d'un distributeur.
-- JUSTIFICATION : Sépare l'événement global de la journée du détail des coupures (2NF).
-- ----------------------------------------------------------------------------
CREATE TABLE session_agent (
    id SERIAL PRIMARY KEY,
    date_session DATE NOT NULL DEFAULT CURRENT_DATE,
    id_agent INT NOT NULL 
        REFERENCES agent(id) 
        ON DELETE RESTRICT,
    statut VARCHAR(20) DEFAULT 'OUVERTE' 
        CHECK (statut IN ('OUVERTE', 'CLOTUREE')), -- OUVERTE = en journée, CLOTUREE = comptes validés
    date_ouverture TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    date_cloture TIMESTAMP WITH TIME ZONE,
    observation TEXT,
    CONSTRAINT uq_agent_date_session UNIQUE (id_agent, date_session) -- Unicité d'une session par jour
);

CREATE INDEX idx_session_agent_date ON session_agent(id_agent, date_session);

-- ----------------------------------------------------------------------------
-- 5. TABLE : session_agent_detail
-- RÔLE : Fiche de suivi analytique par coupure pour l'agent.
-- JUSTIFICATION : Reconstitue fidèlement les colonnes du tableau manuscrit :
-- Pris (Départ + Réappro), Vendu, Recette Versée, et Reste Calculé.
-- ----------------------------------------------------------------------------
CREATE TABLE session_agent_detail (
    id SERIAL PRIMARY KEY,
    id_session INT NOT NULL 
        REFERENCES session_agent(id) 
        ON DELETE CASCADE,                      -- Si la session est annulée, ses lignes le sont aussi
    id_valeur INT NOT NULL 
        REFERENCES type_valeur(id) 
        ON DELETE RESTRICT,
    dotation_depart INT NOT NULL DEFAULT 0 
        CHECK (dotation_depart >= 0),           -- Pris le matin avant de partir
    reapprovisionnement INT NOT NULL DEFAULT 0 
        CHECK (reapprovisionnement >= 0),       -- Pris en cours de journée
    quantite_vendue INT NOT NULL DEFAULT 0 
        CHECK (quantite_vendue >= 0),           -- Déclaré vendu lors du retour
    recette_versee NUMERIC(12, 2) NOT NULL DEFAULT 0.00 
        CHECK (recette_versee >= 0),            -- Espèces déposées à la caisse
    -- Colonne calculée automatiquement par PostgreSQL : Reste = (Départ + Réappro) - Vendu
    reste_physique INT GENERATED ALWAYS AS (
        (dotation_depart + reapprovisionnement) - quantite_vendue
    ) STORED,
    -- Contrainte métier absolue : On ne peut jamais vendre plus que ce que l'on a reçu
    CONSTRAINT chk_quantite_vendue_max CHECK (
        quantite_vendue <= (dotation_depart + reapprovisionnement)
    ),
    -- Une coupure donnée n'apparaît qu'une seule fois par session
    CONSTRAINT uq_session_valeur UNIQUE (id_session, id_valeur)
);

-- ----------------------------------------------------------------------------
-- 6. VUE : vue_stock_central_disponible
-- RÔLE : Calcul instantané du stock réel et de la valeur financière en réserve.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vue_stock_central_disponible AS
SELECT 
    v.id AS id_valeur,
    v.code,
    v.libelle,
    v.valeur_nominale,
    COALESCE(SUM(CASE WHEN m.type_mouvement = 'ENTREE' THEN m.quantite ELSE -m.quantite END), 0)::INT AS stock_physique,
    (COALESCE(SUM(CASE WHEN m.type_mouvement = 'ENTREE' THEN m.quantite ELSE -m.quantite END), 0) * v.valeur_nominale)::NUMERIC(12,2) AS valeur_totale_stock
FROM type_valeur v
LEFT JOIN mouvement_stock_central m ON v.id = m.id_valeur
GROUP BY v.id, v.code, v.libelle, v.valeur_nominale
ORDER BY v.valeur_nominale ASC;