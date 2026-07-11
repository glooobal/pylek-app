create table if not exists air_quality_cache (
  id uuid primary key default gen_random_uuid(),
  tile_id text not null,
  tile_zoom smallint not null default 13,
  data jsonb not null,
  fetched_at timestamptz not null default now(),
  expires_at timestamptz not null,
  unique (tile_id)
);

alter table air_quality_cache enable row level security;

create policy "air_quality_cache_anon_select"
  on air_quality_cache for select
  to anon
  using (true);

create policy "air_quality_cache_service_insert"
  on air_quality_cache for insert
  to service_role
  with check (true);

create policy "air_quality_cache_service_update"
  on air_quality_cache for update
  to service_role
  using (true);

create index if not exists air_quality_cache_expires_at_idx on air_quality_cache (expires_at);
create index if not exists air_quality_cache_tile_id_idx on air_quality_cache (tile_id);

create table if not exists pollen_cache (
  id uuid primary key default gen_random_uuid(),
  tile_id text not null,
  tile_zoom smallint not null default 13,
  date_from date not null,
  date_to date not null,
  data jsonb not null,
  fetched_at timestamptz not null default now(),
  unique (tile_id)
);

alter table pollen_cache enable row level security;

create policy "pollen_cache_anon_select"
  on pollen_cache for select
  to anon
  using (true);

create policy "pollen_cache_service_insert"
  on pollen_cache for insert
  to service_role
  with check (true);

create policy "pollen_cache_service_update"
  on pollen_cache for update
  to service_role
  using (true);

create index if not exists pollen_cache_tile_id_idx on pollen_cache (tile_id);
