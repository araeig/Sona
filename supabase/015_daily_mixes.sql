create table public.daily_mixes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  position   integer not null,
  name       text not null,
  subtitle   text,
  cover_url  text,
  created_at timestamptz not null default now(),
  unique (user_id, position)
);

create table public.daily_mix_tracks (
  mix_id   uuid not null references public.daily_mixes(id) on delete cascade,
  track_id uuid not null references public.tracks(id) on delete cascade,
  position integer not null,
  primary key (mix_id, position)
);

alter table public.daily_mixes enable row level security;
alter table public.daily_mix_tracks enable row level security;

create policy "own mixes read" on public.daily_mixes
  for select to authenticated using (user_id = (select auth.uid()));

create policy "own mix tracks read" on public.daily_mix_tracks
  for select to authenticated
  using (exists (
    select 1 from public.daily_mixes m
    where m.id = mix_id and m.user_id = (select auth.uid())
  ));

notify pgrst, 'reload schema';
