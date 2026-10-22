// ============================================================================
// FICHIER : backend/db.js
// DESCRIPTION : Gestion du pool de connexions PostgreSQL
// ============================================================================

const { Pool } = require('pg');
require('dotenv').config();

// Configuration du pool à partir des variables d'environnement
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'gestion_stock_timbre',
  password: process.env.DB_PASSWORD,
  port: parseInt(process.env.DB_PORT, 10) || 5432,
  max: 10,                     // Nombre maximal de connexions simultanées
});

pool.on('connect', () => {
  console.log('Base de données PostgreSQL connectée avec succès.');
});

pool.on('error', (err) => {
  console.error('Erreur critique sur le pool PostgreSQL :', err.message);
  process.exit(-1);
});

module.exports = pool;