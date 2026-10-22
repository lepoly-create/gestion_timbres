-- Initialisation des timbres officiels
INSERT INTO type_valeur (libelle, valeur_nominale, categorie) VALUES
('Timbre 100F', 100, 'Timbre'),
('Timbre 500F', 500, 'Timbre'),
('Timbre 1000F', 1000, 'Timbre');

-- Mouvements initiaux au stock central (Photo 1 : Entrée 50, Sortie 25, Entrée 75)
INSERT INTO fiche_stock_central (reference_mvt, date_mvt, id_valeur, entree, sortie, motif, beneficiaire) VALUES
('MVT-001', '2026-10-01', 1, 50, 0, 'Dotation reçue régie', 'Magasin Central'),
('MVT-002', '2026-10-02', 1, 0, 25, 'Dotation agent', 'Koffi'),
('MVT-003', '2026-10-03', 1, 75, 0, 'Réapprovisionnement', 'Magasin Central');

-- Ligne de suivi agent (Photo 6 : 50 pris, 25 vendus, 2500 versés, reste 25)
INSERT INTO suivi_distribution_vente (date_operation, agent_nom, id_valeur, qte_recue, qte_vendue, recette_versee, observation) VALUES
('2026-10-02', 'Koffi', 1, 50, 25, 2500.00, 'RàS - Caisse conforme');
