# ZeetaFin ERP - Frontend

## Description

ZeetaFin ERP is the web frontend for Zeeta PLC's Enterprise Resource Planning system. It provides an intuitive interface for managing the company's financial operations, including General Ledger, Accounts Payable, Accounts Receivable, Cash Management, Budgeting, and Fixed Assets.

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Next.js 14 (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Icons | Lucide React |
| Auth | JWT (localStorage) |
| State | React Context |

---

## Prerequisites

- Node.js v18+
- Backend API running (see [ZeetaFin-BE](https://github.com/Muhyideeeen/ZeetaFin-BE))

---

## Setup

### 1. Clone and install

```bash
git clone https://github.com/Muhyideeeen/ZeetaFin-FE.git
cd ZeetaFin-FE
npm install
```

### 2. Configure environment

Copy `.env.local.example` to `.env.local` and update the API URL:

```bash
cp .env.local.example .env.local
```

### 3. Start the dev server

```bash
npm run dev
```

The app runs on `http://localhost:3000`.

### 4. Production build

```bash
npm run build
npm start
```

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NEXT_PUBLIC_API_URL` | No | `http://localhost:3001/api` | Backend API base URL |

### Example .env.local

```env
# Local development
NEXT_PUBLIC_API_URL=http://localhost:3001/api

# Production (e.g., Vercel / Docker)
# NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api
```

---

## Pages

| Route | Description |
|-------|-------------|
| `/login` | Authentication page |
| `/dashboard` | KPIs, cash position, AP/AR aging, quick actions |
| `/gl` | Chart of Accounts, Journal Entries, Trial Balance, P&L |
| `/ap` | Vendors, AP Invoices, Aging Reports |
| `/ar` | Customers, AR Invoices, Aging Reports |
| `/cash` | Bank Accounts, Cash Position, Transactions |
| `/budgeting` | Budgets, Variance Analysis |
| `/fixed-assets` | Asset Register, Depreciation Schedule |
| `/users` | User Management (admin only) |

---

## Project Structure

```
├── app/
│   ├── layout.tsx               # Root layout with auth provider
│   ├── page.tsx                 # Home redirect
│   ├── login/page.tsx           # Login page
│   ├── dashboard/page.tsx       # Dashboard with KPIs
│   ├── gl/page.tsx              # General Ledger
│   ├── ap/page.tsx              # Accounts Payable
│   ├── ar/page.tsx              # Accounts Receivable
│   ├── cash/page.tsx            # Cash Management
│   ├── budgeting/page.tsx       # Budgeting & Forecasting
│   ├── fixed-assets/page.tsx    # Fixed Asset Management
│   └── users/page.tsx           # User Management
├── components/
│   ├── AppLayout.tsx            # Authenticated layout wrapper
│   ├── Sidebar.tsx              # Navigation sidebar
│   ├── DataTable.tsx            # Reusable table component
│   └── StatCard.tsx             # Reusable stat card
├── lib/
│   ├── api.ts                   # API client (fetch wrapper)
│   └── auth.tsx                 # Auth context & provider
└── .env.local                   # Environment config (not committed)
```

---

## License

Private — Zeeta PLC
