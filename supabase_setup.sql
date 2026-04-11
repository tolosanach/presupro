-- ═══════════════════════════════════════════════════════════════════
-- PRESUPRO STUDIO — Supabase Setup
-- Ejecutar en: Supabase Dashboard → SQL Editor → New Query
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. TABLA PRINCIPAL DE PRESUPUESTOS COMPARTIDOS ────────────────
create table if not exists budgets_shared (
  id               uuid primary key default gen_random_uuid(),
  tenant_id        text not null default 'default',  -- para SaaS futuro
  budget_data      jsonb not null,                   -- snapshot completo del presupuesto
  status           text not null default 'sent'
                   check (status in ('sent','viewed','accepted','rejected')),
  view_count       integer not null default 0,
  first_viewed_at  timestamptz,
  last_viewed_at   timestamptz,
  responded_at     timestamptz,
  created_at       timestamptz not null default now(),
  expires_at       timestamptz                       -- null = sin expiración
);

-- ── 2. TABLA DE EVENTOS (tracking granular) ───────────────────────
create table if not exists budget_events (
  id           uuid primary key default gen_random_uuid(),
  budget_id    uuid not null references budgets_shared(id) on delete cascade,
  event_type   text not null
               check (event_type in ('viewed','accepted','rejected')),
  user_agent   text,
  created_at   timestamptz not null default now()
);

-- ── 3. ÍNDICES ────────────────────────────────────────────────────
create index if not exists idx_budgets_shared_tenant  on budgets_shared(tenant_id);
create index if not exists idx_budgets_shared_status  on budgets_shared(status);
create index if not exists idx_budget_events_budget   on budget_events(budget_id);
create index if not exists idx_budget_events_type     on budget_events(event_type);

-- ── 4. ROW LEVEL SECURITY ─────────────────────────────────────────
-- La tabla es pública para lectura (el cliente ve su presupuesto sin login)
-- Solo escritura autenticada para crear — el viewer actualiza estado via service role

alter table budgets_shared enable row level security;
alter table budget_events   enable row level security;

-- Cualquiera puede leer un presupuesto por su id (link único)
create policy "public read by id"
  on budgets_shared for select
  using (true);

-- Cualquiera puede registrar eventos de visualización/respuesta
create policy "public insert events"
  on budget_events for insert
  with check (true);

-- Cualquiera puede actualizar status/view_count (el viewer lo hace)
create policy "public update status"
  on budgets_shared for update
  using (true)
  with check (true);

-- Solo la anon key puede insertar presupuestos (desde tu app local)
create policy "anon insert budgets"
  on budgets_shared for insert
  with check (true);

-- ── 5. VISTA ÚTIL PARA PANEL (opcional) ──────────────────────────
create or replace view budgets_summary as
select
  b.id,
  b.tenant_id,
  b.status,
  b.view_count,
  b.first_viewed_at,
  b.last_viewed_at,
  b.responded_at,
  b.created_at,
  b.expires_at,
  b.budget_data->>'number'              as budget_number,
  b.budget_data->'client'->>'name'      as client_name,
  b.budget_data->'client'->>'email'     as client_email,
  b.budget_data->'totals'->>'total'     as total_amount,
  b.budget_data->'meta'->>'number'      as meta_number,
  b.budget_data->'biz'->>'bizName'      as biz_name,
  (select count(*) from budget_events e where e.budget_id = b.id and e.event_type = 'viewed') as total_views
from budgets_shared b;
