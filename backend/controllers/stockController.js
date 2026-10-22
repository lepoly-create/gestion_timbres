const pool = require('../db');
const Q = require('../db/queries/stockQueries');

exports.getValeurs = async (req, res) => {
  try {
    const { rows } = await pool.query(Q.GET_TYPES_VALEURS);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.getStockDisponible = async (req, res) => {
  try {
    const { rows } = await pool.query(Q.GET_STOCK_DISPONIBLE);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.getHistorique = async (req, res) => {
  try {
    const { rows } = await pool.query(Q.GET_HISTORIQUE_MOUVEMENTS);
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.approvisionner = async (req, res) => {
  const { id_valeur, quantite, motif } = req.body;
  const qte = parseInt(quantite, 10);

  if (!id_valeur || isNaN(qte) || qte <= 0) {
    return res.status(400).json({ success: false, error: 'Valeur et quantité valide (>0) requises.' });
  }

  try {
    const ref = `IN-${Date.now()}`;
    const { rows } = await pool.query(Q.INSERT_ENTREE_MAGASIN, [
      ref, id_valeur, qte, motif || 'Approvisionnement régie'
    ]);
    res.status(201).json({ success: true, message: 'Stock magasin crédité', data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};