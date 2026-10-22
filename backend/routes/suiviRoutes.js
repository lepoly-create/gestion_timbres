const express = require('express');
const router = express.Router();
const ctrl = require('../controllers/suiviController');

router.get('/tableau', ctrl.getTableauSuivi);
router.post('/dotation', ctrl.remettreDotation);
router.post('/cloture', ctrl.enregistrerRetourVentes);

module.exports = router;