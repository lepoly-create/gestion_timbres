const pool = require('../db');
const Q = require('../db/queries/suiviQueries');

// Prise de timbres par l'agent : Transaction Atomique
exports.remettreDotation = async (req, res) => {
  const { agent_nom, id_valeur, quantite, date_operation } = req.body;
  const qte = parseInt(quantite, 10);

  if (!agent_nom?.trim() || !id_valeur || isNaN(qte) || qte <= 0) {
    return res.status(400).json({ success: false, error: 'Informations de dotation incomplètes.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Verrouiller la ligne et vérifier la réserve centrale
    const checkRes = await client.query(Q.LOCK_STOCK_VALEUR, [id_valeur]);
    if (checkRes.rows.length === 0) throw new Error('Coupure introuvable.');

    const dispo = checkRes.rows[0].disponible;
    if (dispo < qte) {
      throw new Error(`Stock insuffisant (${dispo} disponibles, ${qte} demandés).`);
    }

    // 2. Décrémenter le stock central (Page 1)
    const refSortie = `OUT-${Date.now()}`;
    await client.query(Q.INSERT_SORTIE_DOTATION, [refSortie, id_valeur, qte, agent_nom.trim()]);

    // 3. Ouvrir la ligne de suivi de l'agent (Page 2)
    const dateOp = date_operation || new Date().toISOString().split('T')[0];
    const { rows } = await client.query(Q.INSERT_SUIVI_AGENT, [
      dateOp, agent_nom.trim(), id_valeur, qte, 0, 0.00, 'Dotation remise'
    ]);

    await client.query('COMMIT');
    res.status(201).json({ success: true, message: 'Dotation délivrée avec succès', data: rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(400).json({ success: false, error: err.message });
  } finally {
    client.release();
  }
};

// Clôture des ventes du soir
exports.enregistrerRetourVentes = async (req, res) => {
  const { id_suivi, qte_vendue, recette_versee, observation } = req.body;
  const vendus = parseInt(qte_vendue, 10);
  const versee = parseFloat(recette_versee);

  if (!id_suivi || isNaN(vendus) || isNaN(versee)) {
    return res.status(400).json({ success: false, error: 'Données de clôture invalides.' });
  }

  try {
    const { rows } = await pool.query(Q.UPDATE_VENTE_RETOUR, [
      vendus, versee, observation || 'Clôture effectuée', id_suivi
    ]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Ligne de suivi introuvable.' });
    }

    res.json({ success: true, message: 'Ventes et versement validés', data: rows[0] });
  } catch (err) {
    res.status(400).json({ success: false, error: err.message });
  }
};

exports.getTableauSuivi = async (req, res) => {
  try {
    const { rows } = await pool.query(Q.GET_TABLEAU_RECAPITULATIF);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};