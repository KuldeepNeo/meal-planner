# Meal Planner Application - Backend

This folder contains the complete Node.js/Express.js backend and SQLite database for the Meal Planner Application.

## Technology Stack

* **Node.js**: v24.16.0 / v25.x
* **Express.js**: v5.0.0 (API Router and Middleware orchestration)
* **SQLite**: Promise-based wrapper (`sqlite` with `sqlite3` driver)
* **Testing**: Jest and Supertest
* **Authentication**: JSON Web Token (JWT)

---

## Folder Structure

```text
backend/
├── src/
│   ├── app.js               # Express app config and route bindings
│   ├── server.js            # Main executable booting the server
│   ├── config/
│   │   └── database.js      # SQLite connection settings & foreign keys enablement
│   ├── middleware/
│   │   ├── auth.js          # JWT and session authentication check
│   │   ├── error.js         # Global error response handler
│   │   └── validate.js      # Request body validation schemas
│   ├── models/
│   │   └── db.js            # SQLite database schema migration script
│   └── routes/
│       ├── auth.js          # Authentication (Register, Login, Password Reset)
│       ├── grocery.js       # Grocery Inventory CRUD and Status updates
│       ├── recipe.js        # Recipes CRUD, validate and consume
│       ├── mealPlan.js      # Meal Plans and items scheduling
│       ├── shoppingList.js  # Shopping List generator and custom items
│       ├── order.js         # Ordering, checkout and delivery lifecycle updates
│       └── analytics.js     # Business success metric KPIs computations
├── scripts/
│   ├── initDb.js            # CLI script to migrate SQLite schema
│   └── seedDb.js            # CLI script to seed default vendor records
├── tests/
│   └── api.test.js          # E2E Jest integration test suite (runs on in-memory DB)
├── package.json
└── .env
```

---

## Getting Started

### 1. Install Dependencies

Install required packages:
```bash
npm install
```

### 2. Configure Environment Variables

Modify the `.env` file in the root of this folder as needed:
```env
PORT=5001
JWT_SECRET=mealplanner_super_jwt_secret_key_2026
DB_FILE=database.sqlite
```

### 3. Initialize & Seed Database

Create the tables and seed default active Vendors:
```bash
npm run db:init
npm run db:seed
```

### 4. Run the Server

Start the API server:
```bash
# Production mode
npm start

# Development mode (with nodemon auto-reloads)
npm run dev
```
The server will bind to port `5001` (or your configured `PORT`), exposing the API routes under `/api/*`.

---

## Running the Test Suite

Execute the integration test suite (runs on an isolated in-memory DB configuration):
```bash
npm test
```
This runs 25 tests covering registration, JWT/refresh authentication, password resets, stock status lifecycles, recipe validation, meal plans, automatic shopping list generation, order checkouts, inventory updates on delivery, and analytics metrics computation.
