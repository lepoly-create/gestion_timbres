// ============================================================================
// FICHIER : backend/db/queries/agentQueries.js
// DESCRIPTION : Centralisation des requêtes SQL pour les Agents et Ventes (Niveau 2)
// ============================================================================

module.exports = {
  // Liste des distributeurs actifs
  GET_AGENTS_ACTIFS: `
    SELECT id, matricule, nom, prenom, telephone 
    FROM agent 
    WHERE statut = 'ACTIF' 
    ORDER BY nom ASC;
  `,

  // Verrouillage de la ligne pour vérifier la disponibilité avant distribution (Anti Race-Condition)
  LOCK_STOCK_MAGASIN: `
    SELECT 
      v.libelle,
      COALESCE(SUM(CASE WHEN m.type_mouvement = 'ENTREE' THEN m.quantite ELSE -m.quantite END), 0)::INT AS disponible
    FROM type_valeur v
    LEFT JOIN mouvement_stock_central m ON v.id = m.id_valeur
    WHERE v.id = $1
    GROUP BY v.id, v.libelle
    FOR UPDATE;
  `,

  // Recherche de la session ouverte du jour pour un agent
  GET_SESSION_JOURNALIERE: `
    SELECT id, statut 
    FROM session_agent 
    WHERE id_agent = $1 AND date_session = $2 AND statut = 'OUVERTE';
  `,

  // Ouverture d'une session journalière
  INSERT_SESSION: `
    INSERT INTO session_agent (id_agent, date_session, statut) 
    VALUES ($1, $2, 'OUVERTE') 
    RETURNING id;
  `,

  // Sortie physique du magasin affectée à un agent
  INSERT_SORTIE_MAGASIN: `
    INSERT INTO mouvement_stock_central (reference_mvt, id_valeur, type_mouvement, quantite, id_agent, motif)
    VALUES ($1, $2, 'SORTIE', $3, $4, $5);
  `,

  // Upsert pour la dotation de départ (matin)
  UPSERT_DOTATION_DEPART: `
    INSERT INTO session_agent_detail (id_session, id_valeur, dotation_depart)
    VALUES ($1, $2, $3)
    ON CONFLICT (id_session, id_valeur)
    DO UPDATE SET dotation_depart = session_agent_detail.dotation_depart + EXCLUDED.dotation_depart
    RETURNING *;
  `,

  // Upsert pour le réapprovisionnement (journée)
  UPSERT_REAPPROVISIONNEMENT: `
    INSERT INTO session_agent_detail (id_session, id_valeur, reapprovisionnement)
    VALUES ($1, $2, $3)
    ON CONFLICT (id_session, id_valeur)
    DO UPDATE SET reapprovisionnement = session_agent_detail.reapprovisionnement + EXCLUDED.reapprovisionnement
    RETURNING *;
  `,

  // Récupération de la valeur faciale d'un timbre
  GET_VALEUR_FACIALE: `
    SELECT valeur_nominale, libelle FROM type_valeur WHERE id = $1;
  `,

  // Verrouillage de la ligne de décharge pour validation de la vente
  LOCK_DETAIL_SESSION: `
    SELECT * FROM session_agent_detail 
    WHERE id_session = $1 AND id_valeur = $2 
    FOR UPDATE;
  `,

  // Mise à jour finale lors du retour de terrain
  UPDATE_CLOTURE_VENTE: `
    UPDATE session_agent_detail
    SET quantite_vendue = $1,
        recette_versee = $2
    WHERE id_session = $3 AND id_valeur = $4
    RETURNING *;
  `,

  // Grand journal de suivi pour l'interface de contrôle
  GET_JOURNAL_AGENT: `
    SELECT 
      s.id AS id_session,
      s.date_session,
      s.statut AS statut_session,
      a.matricule,
      CONCAT(a.nom, ' ', a.prenom) AS agent_nom,
      v.id AS id_valeur,
      v.libelle AS timbre,
      v.valeur_nominale,
      d.dotation_depart,
      d.reapprovisionnement,
      (d.dotation_depart + d.reapprovisionnement) AS total_recu,
      d.quantite_vendue,
      d.reste_physique,
      (d.quantite_vendue * v.valeur_nominale)::NUMERIC(12,2) AS recette_theorique,
      d.recette_versee,
      (d.recette_versee - (d.quantite_vendue * v.valeur_nominale))::NUMERIC(12,2) AS ecart_caisse
    FROM session_agent s
    JOIN agent a ON s.id_agent = a.id
    JOIN session_agent_detail d ON s.id = d.id_session
    JOIN type_valeur v ON d.id_valeur = v.id
    ORDER BY s.date_session DESC, s.id DESC;
  `
};