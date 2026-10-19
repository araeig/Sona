create table public.track_events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  track_id     uuid not null references public.tracks(id) on delete cascade,
  event_type   text not null check (event_type in ('play', 'skip', 'like')),
  listened_sec integer,
  created_at   timestamptz not null default now()
);

create index track_events_user_time_idx
  on public.track_events (user_id, created_at desc);

alter table public.track_events enable row level security;

create policy "own events read" on public.track_events
  for select to authenticated using (user_id = (select auth.uid()));

create policy "own events insert" on public.track_events
  for insert to authenticated with check (user_id = (select auth.uid()));

notify pgrst, 'reload schema';
