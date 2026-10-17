# ZeetaFin ERP - Backend API

## Description

ZeetaFin ERP is the backend API for Zeeta PLC's Enterprise Resource Planning system. It provides a centralized financial management platform that automates accounting processes, supports informed decision-making, and establishes a single source of truth for all financial data.

This API powers six core financial modules:

- **General Ledger (GL)** — Chart of Accounts, Journal Entries, Trial Balance, Balance Sheet, Profit & Loss
- **Accounts Payable (AP)** — Vendor management, Invoice processing, Payments, Aging analysis
- **Accounts Receivable (AR)** — Customer management, Invoicing, Receipts, Credit notes, Aging reports
- **Cash Management** — Bank accounts, Cash positions, Transactions, Bank reconciliation
- **Budgeting & Forecasting** — Budget creation, Departmental budgets, Variance analysis
- **Fixed Asset Management** — Asset register, Depreciation calculations, Disposal workflow

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | NestJS |
| Language | TypeScript |
| Database | PostgreSQL |
| ORM | TypeORM |
| Authentication | JWT (Passport) |
| API Docs | Swagger (OpenAPI) |
| Validation | class-validator + class-transformer |

---

## Prerequisites

- Node.js v18+
- PostgreSQL v12+

---

## Setup

### 1. Clone and install

```bash
git clone https://github.com/Muhyideeeen/ZeetaFin-BE.git
cd ZeetaFin-BE
npm install
```

### 2. Configure environment

Copy `.env.example` to `.env` and update with your credentials:

```bash
cp .env.example .env
```

### 3. Create the database

```sql
CREATE DATABASE zeetafin;
```

### 4. Seed the admin user and sync tables

```bash
npm run build
npm run setup
```

This creates all tables and an admin user:

- **Email:** `admin@zeeta.com`
- **Password:** `admin123`

### 5. Start the server

```bash
# Development
npm run start:dev

# Production
npm run build
npm run start:prod
```

The API runs on `http://localhost:3001` by default.

Swagger docs available at `http://localhost:3001/api/docs`.

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `3001` | Server port |
| `DB_HOST` | No | `localhost` | PostgreSQL host |
| `DB_PORT` | No | `5432` | PostgreSQL port |
| `DB_USERNAME` | No | `postgres` | PostgreSQL username |
| `DB_PASSWORD` | Yes | — | PostgreSQL password |
| `DB_NAME` | No | `zeetafin` | Database name |
| `JWT_SECRET` | Yes | — | Secret key for JWT tokens |
| `NODE_ENV` | No | `development` | `development` or `production` |
| `DB_SYNC` | No | `true` | Auto-sync database schema on startup |
| `DB_LOGGING` | No | `false` | Enable SQL query logging |

### Example .env

```env
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_password_here
DB_NAME=zeetafin
JWT_SECRET=replace-with-a-long-random-string
NODE_ENV=production
DB_SYNC=true
DB_LOGGING=false
```

---

## Default User Roles

| Role | Description |
|------|-------------|
| `finance_admin` | Full access, manages users and settings |
| `accountant` | Processes transactions and maintains records |
| `ap_officer` | Manages vendor invoices and payments |
| `ar_officer` | Manages customer invoices and collections |
| `treasury_officer` | Monitors cash positions and bank accounts |
| `financial_controller` | Reviews reports and approves transactions |
| `auditor` | Read-only access to financial records |

---

## Project Structure

```
src/
├── main.ts                          # Application entry point
├── app.module.ts                    # Root module
├── seed.ts                          # DB seed script (tables + admin user)
├── common/
│   ├── decorators/roles.decorator.ts
│   ├── enums/user-role.enum.ts
│   └── guards/                      # JWT & role-based guards
├── config/
│   └── jwt.config.ts
└── modules/
    ├── auth/                        # Login, register, JWT
    ├── users/                       # User management
    ├── gl/                          # General Ledger
    ├── ap/                          # Accounts Payable
    ├── ar/                          # Accounts Receivable
    ├── cash-management/             # Cash & bank management
    ├── budgeting/                   # Budgets & forecasting
    └── fixed-asset/                 # Fixed asset lifecycle
```

---

## License

Private — Zeeta PLC
