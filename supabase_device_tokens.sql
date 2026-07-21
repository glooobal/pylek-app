create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  forecast_reminder_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists device_tokens_forecast_reminder_idx
  on device_tokens (forecast_reminder_enabled)
  where forecast_reminder_enabled = true;

alter table device_tokens enable row level security;

-- Only Edge Functions (service_role) can read/write this table
create policy "device_tokens_service_all"
  on device_tokens
  to service_role
  using (true)
  with check (true);
