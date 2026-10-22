-- ============================================================================
-- SCRIPT DDL : Création des 3 tables et de la vue de jointure
-- ============================================================================

DROP VIEW IF EXISTS vue_tableau_professeur_page2;
DROP VIEW IF EXISTS vue_stock_central_disponible;
DROP TABLE IF EXISTS suivi_distribution_vente CASCADE;
DROP TABLE IF EXISTS fiche_stock_central CASCADE;
DROP TABLE IF EXISTS type_valeur CASCADE;

-- ----------------------------------------------------------------------------
-- TABLE 1 : type_valeur (Référentiel des coupures)
-- Rôle : Évite la redondance et fixe la valeur faciale légale.
-- ----------------------------------------------------------------------------
CREATE TABLE type_valeur (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(50) NOT NULL UNIQUE,     -- 'Timbre 100F', 'Timbre 500F', 'Timbre 1000F'
    valeur_nominale INT NOT NULL CHECK (valeur_nominale > 0),
    categorie VARCHAR(30) DEFAULT 'Timbre'   -- Extension future : Ticket, Quittance
);

-- ----------------------------------------------------------------------------
-- TABLE 2 : fiche_stock_central (Page 1 du cours : Grand Livre du Magasin)
-- Rôle : Trace chronologique des entrées (livraisons) et sorties (dotations).
-- ----------------------------------------------------------------------------
CREATE TABLE fiche_stock_central (
    id SERIAL PRIMARY KEY,
    reference_mvt VARCHAR(60) UNIQUE NOT NULL,
    date_mvt DATE NOT NULL DEFAULT CURRENT_DATE,
    id_valeur INT NOT NULL REFERENCES type_valeur(id) ON DELETE RESTRICT,
    entree INT NOT NULL DEFAULT 0 CHECK (entree >= 0),
    sortie INT NOT NULL DEFAULT 0 CHECK (sortie >= 0),
    motif VARCHAR(150) NOT NULL,
    beneficiaire VARCHAR(100),               -- Nom de l'agent si sortie, régie si entrée
    CONSTRAINT chk_mvt_valide CHECK (entree > 0 OR sortie > 0)
);

CREATE INDEX idx_stock_valeur ON fiche_stock_central(id_valeur);

-- ----------------------------------------------------------------------------
-- TABLE 3 : suivi_distribution_vente (Page 2 du cours : Suivi Terrain)
-- Rôle : Enregistrement de chaque agent par coupure (Pris, Vendu, Recette).
-- ----------------------------------------------------------------------------
CREATE TABLE suivi_distribution_vente (
    id SERIAL PRIMARY KEY,
    date_operation DATE NOT NULL DEFAULT CURRENT_DATE,
    agent_nom VARCHAR(100) NOT NULL,
    id_valeur INT NOT NULL REFERENCES type_valeur(id) ON DELETE RESTRICT,
    qte_recue INT NOT NULL CHECK (qte_recue >= 0),        -- Commandé / Reçu
    qte_vendue INT NOT NULL DEFAULT 0 CHECK (qte_vendue >= 0), -- Nombre vendu
    recette_versee NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (recette_versee >= 0),
    observation TEXT,
    CONSTRAINT chk_vente_maximale CHECK (qte_vendue <= qte_recue)
);

CREATE INDEX idx_suivi_agent ON suivi_distribution_vente(agent_nom, date_operation);

-- ----------------------------------------------------------------------------
-- VUE 1 : vue_stock_central_disponible
-- Calcul dynamique du solde magasin restant en direct (Entrées - Sorties).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vue_stock_central_disponible AS
SELECT 
    v.id AS id_valeur,
    v.libelle,
    v.valeur_nominale,
    COALESCE(SUM(m.entree - m.sortie), 0)::INT AS stock_physique,
    (COALESCE(SUM(m.entree - m.sortie), 0) * v.valeur_nominale)::NUMERIC(12, 2) AS valeur_totale_stock
FROM type_valeur v
LEFT JOIN fiche_stock_central m ON v.id = m.id_valeur
GROUP BY v.id, v.libelle, v.valeur_nominale
ORDER BY v.valeur_nominale ASC;

-- ----------------------------------------------------------------------------
-- VUE 2 : vue_tableau_suite
-- Jointure matérialisant toutes les colonnes du tableau manuscrit.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vue_tableau_suite AS
SELECT 
    s.id,
    s.date_operation,
    s.agent_nom,
    v.id AS id_valeur,
    v.libelle AS timbre,
    v.valeur_nominale,
    s.qte_recue,
    (s.qte_recue * v.valeur_nominale)::NUMERIC(12, 2) AS valeur_stock_recu,
    s.qte_vendue,
    s.recette_versee,
    (s.qte_vendue * v.valeur_nominale)::NUMERIC(12, 2) AS recette_attendue,
    (s.recette_versee - (s.qte_vendue * v.valeur_nominale))::NUMERIC(12, 2) AS ecart_caisse,
    (s.qte_recue - s.qte_vendue)::INT AS reste_en_nombre,
    ((s.qte_recue - s.qte_vendue) * v.valeur_nominale)::NUMERIC(12, 2) AS valeur_du_reste,
    s.observation
FROM suivi_distribution_vente s
JOIN type_valeur v ON s.id_valeur = v.id;