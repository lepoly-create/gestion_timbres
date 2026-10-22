# Gestion des Timbres & Valeurs Inactives

[![Node.js](https://img.shields.io/badge/Node.js-v18+-green.svg?logo=node.js)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-v5.3-lightgrey.svg?logo=express)](https://expressjs.com/)
[![React](https://img.shields.io/badge/React-v19-blue.svg?logo=react)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-v8-purple.svg?logo=vite)](https://vitejs.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-v14+-blue.svg?logo=postgresql)](https://www.postgresql.org/)
[![TailwindCSS](https://img.shields.io/badge/TailwindCSS-v4-cyan.svg?logo=tailwindcss)](https://tailwindcss.com/)

Plateforme complète de gestion, distribution et suivi comptable des timbres et valeurs inactives (billetterie, quittances, timbres fiscaux). 

---

## Contexte & Objectifs du Projet

Ce projet s'inscrit dans le cadre du module pratique de **Gestion des Stocks et Comptabilité des Matières (Projet Salami)**. Il a pour objectif de digitaliser et d'automatiser le processus de gestion manuscrite des valeurs fiduciaires :

1. **Le Grand Livre du Magasin (Stock Central)** :
   - Enregistrement des entrées (approvisionnements régie / livraisons).
   - Traçabilité des sorties (dotations accordées aux agents distributeurs).
   - Calcul automatisé et en direct des stocks physiques et de la valeur marchande par coupure (100F, 500F, 1000F, etc.).

2. **Le Registre de Suivi Terrain (Agents Distributeurs)** :
   - Attribution des dotations d'un agent par coupure.
   - Saisie des quantités vendues en fin de journée et enregistrement des recettes versées.
   - **Rapprochement financier immédiat** : calcul automatique de la recette attendue, de l'écart de caisse (surplus ou déficit) et du solde physique restant entre les mains de l'agent.

3. **Garantie d'intégrité transactionnelle** :
   - Utilisation de transactions SQL atomiques (`BEGIN ... COMMIT / ROLLBACK`) avec verrouillage pour empêcher toute distribution de stock central non disponible.

---

## Equipe & Répartition des Rôles (3 Collaborateurs)

Pour assurer une collaboration fluide et sans conflit, voici la répartition recommandée des responsabilités :

| Membre | Rôle Principal | Périmètre & Responsabilités |
| :--- | :--- | :--- |
| **Collaborateur 1** | **Lead Backend & Database** | Modélisation SQL, gestion des transactions, intégrité des données, endpoints API REST (Node/Express). |
| **Collaborateur 2** | **Lead Frontend & UI/UX** | Conception des interfaces React / Tailwind, formulaires de saisie, dashboards interactifs, responsive design. |
| **Collaborateur 3** | **Intégration, Métier & Rapprochement** | Liaison API / Frontend, logique de calcul des écarts de caisse, exports d'états (PDF/Excel), tests et validation. |

---

## Structure du Projet

```text
gestion_timbres/
├── .gitignore                     # Configuration des exclusions Git
├── README.md                      # Documentation du projet
├── LICENSE                        # Licence du projet
│
├── backend/                       # API REST & Base de données
│   ├── .env.example               # Modèle des variables d'environnement
│   ├── package.json               # Dépendances backend
│   ├── server.js                  # Point d'entrée du serveur Express
│   ├── db.js                      # Configuration du pool PostgreSQL
│   ├── controllers/               # Logique métier des requêtes
│   │   ├── stockController.js     # Gestion des entrées/sorties magasin central
│   │   └── suiviController.js     # Gestion des dotations et clôtures agents
│   ├── routes/                    # Définition des routes Express
│   │   ├── stockRoutes.js
│   │   └── suiviRoutes.js
│   └── db/                        # Scripts SQL
│       ├── schema.sql             # Création des tables, vues et contraintes
│       ├── seed.sql               # Données de test initiales
│       └── queries/               # Requêtes SQL modulaires
│
└── frontend/                      # Application Client (SPA)
    ├── package.json               # Dépendances frontend
    ├── vite.config.js             # Configuration du bundler Vite
    ├── index.html                 # Point d'entrée HTML
    └── src/                       # Code source React
        ├── App.jsx                # Composant principal
        ├── main.jsx               # Montage React dans le DOM
        └── index.css              # Styles globaux & Tailwind CSS
```

---

## Guide de Démarrage Rapide

### Prérequis
- [Node.js](https://nodejs.org/) (version 18 ou supérieure)
- [PostgreSQL](https://www.postgresql.org/) (version 14 ou supérieure)
- [Git](https://git-scm.com/)

---

### 1. Cloner le dépôt
```bash
git clone https://github.com/lepoly-create/gestion_timbres.git
cd gestion_timbres
```

---

### 2. Configuration de la Base de Données PostgreSQL

1. Ouvrez votre terminal PostgreSQL (`psql`) ou **pgAdmin** et créez la base de données :
   ```sql
   CREATE DATABASE gestion_stock_timbre;
   ```
2. Exécutez le script de schéma DDL :
   ```bash
   psql -U postgres -d gestion_stock_timbre -f backend/db/schema.sql
   ```
3. *(Optionnel)* Chargez les données d'exemples :
   ```bash
   psql -U postgres -d gestion_stock_timbre -f backend/db/seed.sql
   ```

---

### 3. Installation et Démarrage du Backend

1. Rendez-vous dans le dossier `backend` :
   ```bash
   cd backend
   npm install
   ```

2. Créez votre fichier de configuration locale `.env` à partir du modèle :
   ```bash
   # Sur Windows (PowerShell) :
   Copy-Item .env.example .env

   # Sur Linux / macOS :
   cp .env.example .env
   ```

3. Modifiez le fichier `.env` avec vos identifiants PostgreSQL :
   ```env
   PORT=3000
   DB_USER=postgres
   DB_PASSWORD=votre_mot_de_passe
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=gestion_stock_timbre
   ```

4. Lancez le serveur en mode développement (avec rechargement automatique) :
   ```bash
   npm run dev
   ```
   > Le serveur démarre sur : `http://localhost:3000`  
   > Test de santé : `http://localhost:3000/api/health`

---

### 4. Installation et Démarrage du Frontend

Dans un **deuxième terminal** :

1. Rendez-vous dans le dossier `frontend` :
   ```bash
   cd frontend
   npm install
   ```

2. Démarrez le serveur de développement Vite :
   ```bash
   npm run dev
   ```
   > L'application web s'ouvre sur : `http://localhost:5173`

---

## Référentiel des Endpoints API

### Stock Central (`/api/stock`)
| Méthode | Route | Description |
| :--- | :--- | :--- |
| `GET` | `/api/stock/valeurs` | Liste de toutes les coupures (100F, 500F, etc.) |
| `GET` | `/api/stock/disponible` | Solde disponible et valeur totale du magasin central |
| `GET` | `/api/stock/historique` | Historique chronologique des entrées et sorties |
| `POST` | `/api/stock/approvisionner` | Enregistre une livraison régie (crédit stock central) |

### Suivi des Agents & Ventes (`/api/suivi`)
| Méthode | Route | Description |
| :--- | :--- | :--- |
| `POST` | `/api/suivi/dotation` | Débite le stock central et attribue des timbres à un agent (transaction atomique) |
| `PUT` | `/api/suivi/cloture` | Valide les ventes de l'agent, le versement et calcule les écarts |
| `GET` | `/api/suivi/tableau` | Retourne la vue consolidée (Page 2 du cours) avec écarts et restes |

---

## Guide de Collaboration & Bonnes Pratiques Git

Pour éviter d'écraser le travail des autres ou de créer des conflits Git :

### 1. Toujours synchroniser avant de commencer à coder
```bash
git checkout main
git pull origin main
```

### 2. Créer une branche dédiée pour chaque fonctionnalité
Ne codez jamais directement sur la branche `main` :
```bash
# Format recommandé : feature/nom-de-la-fonctionnalite
git checkout -b feature/formulaire-dotation
```

### 3. Convention de messages de commit
Adoptez la convention **Conventional Commits** :
- `feat: ...` (Ajout d'une nouvelle fonctionnalité)
- `fix: ...` (Correction d'un bug)
- `docs: ...` (Modification de la documentation)
- `style: ...` (Mise en forme CSS / UI)
- `refactor: ...` (Nettoyage de code sans changement fonctionnel)

*Exemple :* `git commit -m "feat: ajout du formulaire d'attribution de dotation"`

### 4. Publier sa branche et faire une Pull Request (PR)
```bash
git push -u origin feature/formulaire-dotation
```
Créez ensuite une **Pull Request** sur GitHub et demandez à au moins un autre membre de relire et valider avant de fusionner (*merge*) dans `main`.

---

## Règles de Sécurité
- **Ne jamais commiter le fichier `.env`** : Il contient les mots de passe de votre base de données locale.
- Seul le fichier `.env.example` doit être versionné pour documenter les variables requises.
- Le dossier `node_modules/` est strictement ignoré par le fichier `.gitignore`.

---

## Licence
Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus d'informations.
