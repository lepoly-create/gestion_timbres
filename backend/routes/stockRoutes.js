const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/stockController');

router.get('/valeurs', ctrl.getValeurs);
router.get('/disponible', ctrl.getStockDisponible);
router.get('/historique', ctrl.getHistorique);
router.post('/approvisionner', ctrl.approvisionner);

module.exports = router;