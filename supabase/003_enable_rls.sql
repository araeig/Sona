-- 003_enable_rls.sql
-- Включает RLS на всех таблицах и добавляет правила доступа.
-- Каталог читают все вошедшие; лайки, подписки, история — только свои;
-- плейлисты — свои и публичные. Python-сервис (service_role) проходит мимо RLS.

alter table public.profiles         enable row level security;
alter table public.artists          enable row level security;
alter table public.genres           enable row level security;
alter table public.artist_genres    enable row level security;
alter table public.tracks           enable row level security;
alter table public.playlists        enable row level security;
alter table public.playlist_tracks  enable row level security;
alter table public.liked_tracks     enable row level security;
alter table public.play_history     enable row level security;
alter table public.followed_artists enable row level security;

-- Каталог: читают все вошедшие
create policy "catalog read" on public.tracks        for select to authenticated using (true);
create policy "catalog read" on public.artists       for select to authenticated using (true);
create policy "catalog read" on public.genres        for select to authenticated using (true);
create policy "catalog read" on public.artist_genres for select to authenticated using (true);

-- Профили: видят все вошедшие, меняют только свой
create policy "profiles read" on public.profiles
  for select to authenticated using (true);
create policy "profiles insert own" on public.profiles
  for insert to authenticated with check (id = (select auth.uid()));
create policy "profiles update own" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- Лайки, подписки, история: только свои
create policy "own rows" on public.liked_tracks for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own rows" on public.followed_artists for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own rows" on public.play_history for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Плейлисты: видны свои и публичные, меняются только свои
create policy "playlists read" on public.playlists for select to authenticated
  using (user_id = (select auth.uid()) or is_private = false);
create policy "playlists write own" on public.playlists for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "playlist tracks read" on public.playlist_tracks for select to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id
      and (p.user_id = (select auth.uid()) or p.is_private = false)));
create policy "playlist tracks write own" on public.playlist_tracks for all to authenticated
  using (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())))
  with check (exists (
    select 1 from public.playlists p
    where p.id = playlist_id and p.user_id = (select auth.uid())));

-- Проверка username при регистрации (работает и до входа)
create or replace function public.is_username_available(p_username text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not exists (select 1 from public.profiles where username = p_username);
$$;
grant execute on function public.is_username_available(text) to anon, authenticated;

notify pgrst, 'reload schema';
