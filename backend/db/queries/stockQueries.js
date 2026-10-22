module.exports = {
  GET_TYPES_VALEURS: `
    SELECT id, libelle, valeur_nominale, categorie 
    FROM type_valeur 
    ORDER BY valeur_nominale ASC;
  `,

  GET_STOCK_DISPONIBLE: `
    SELECT * FROM vue_stock_central_disponible;
  `,

  GET_HISTORIQUE_MOUVEMENTS: `
    SELECT 
      m.id,
      m.reference_mvt,
      m.date_mvt,
      v.libelle AS timbre,
      v.valeur_nominale,
      m.entree,
      m.sortie,
      SUM(m.entree - m.sortie) OVER (PARTITION BY m.id_valeur ORDER BY m.date_mvt, m.id) AS solde_chronologique,
      m.motif,
      m.beneficiaire
    FROM fiche_stock_central m
    JOIN type_valeur v ON m.id_valeur = v.id
    ORDER BY m.date_mvt DESC, m.id DESC;
  `,

  INSERT_ENTREE_MAGASIN: `
    INSERT INTO fiche_stock_central (reference_mvt, id_valeur, entree, sortie, motif, beneficiaire)
    VALUES ($1, $2, $3, 0, $4, 'Magasin Central')
    RETURNING *;
  `
};
