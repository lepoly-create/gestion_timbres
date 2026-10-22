const express = require('express');
const cors = require('cors');
require('dotenv').config();

const stockRoutes = require('./routes/stockRoutes');
const suiviRoutes = require('./routes/suiviRoutes');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/stock', stockRoutes);
app.use('/api/suivi', suiviRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'API Timbres opérationnelle' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Backend opérationnel sur http://localhost:${PORT}`);
});