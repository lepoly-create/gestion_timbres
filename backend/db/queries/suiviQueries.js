module.exports = {
  // Verrou de sécurité sur le stock central
  LOCK_STOCK_VALEUR: `
    SELECT 
      v.libelle,
      COALESCE(SUM(m.entree - m.sortie), 0)::INT AS disponible
    FROM type_valeur v
    LEFT JOIN fiche_stock_central m ON v.id = m.id_valeur
    WHERE v.id = $1
    GROUP BY v.id, v.libelle
    FOR UPDATE;
  `,

  INSERT_SORTIE_DOTATION: `
    INSERT INTO fiche_stock_central (reference_mvt, id_valeur, entree, sortie, motif, beneficiaire)
    VALUES ($1, $2, 0, $3, 'Dotation distributeur', $4);
  `,

  INSERT_SUIVI_AGENT: `
    INSERT INTO suivi_distribution_vente (date_operation, agent_nom, id_valeur, qte_recue, qte_vendue, recette_versee, observation)
    VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *;
  `,

  UPDATE_VENTE_RETOUR: `
    UPDATE suivi_distribution_vente
    SET qte_vendue = $1,
        recette_versee = $2,
        observation = $3
    WHERE id = $4
    RETURNING *;
  `,

  GET_TABLEAU_RECAPITULATIF: `
    SELECT * FROM vue_tableau_professeur_page2
    ORDER BY date_operation DESC, id DESC;
  `
};
