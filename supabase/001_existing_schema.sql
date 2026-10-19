-- 001_existing_schema.sql
-- Схема Sona до добавления ИИ-функций (снята с Supabase 8 октября 2026).
-- Не нужно выполнять заново: это запись того, что уже есть в базе.

create table public.profiles (
  id           uuid primary key default gen_random_uuid(),
  display_name text,
  username     text,
  avatar_url   text,
  bio          text,
  settings     jsonb,                       -- эквалайзер: bass / mid / treble
  created_at   timestamptz not null default now()
);

create table public.genres (
  id        uuid primary key default gen_random_uuid(),
  name      text not null,
  cover_url text
);

create table public.artists (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  avatar_url     text,
  bio            text,
  listener_count integer default 0
);

create table public.artist_genres (
  id        uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artists(id),
  genre_id  uuid not null references public.genres(id)
);

create table public.tracks (
  id           uuid primary key default gen_random_uuid(),
  artist_id    uuid not null references public.artists(id),
  title        text not null,
  audio_url    text,
  cover_url    text,
  genre_id     uuid not null references public.genres(id),
  duration_sec integer,
  play_count   integer default 0,
  created_at   timestamptz not null default now()
);

create table public.playlists (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id),
  name        text not null,
  description text,
  cover_url   text,
  is_private  boolean default true,
  created_at  timestamptz not null default now()
);

create table public.playlist_tracks (
  id          uuid primary key default gen_random_uuid(),
  playlist_id uuid not null references public.playlists(id),
  track_id    uuid not null references public.tracks(id),
  position    integer,
  added_at    timestamptz default now()
);

create table public.liked_tracks (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references public.profiles(id),
  track_id uuid not null references public.tracks(id),
  liked_at timestamptz default now()
);

create table public.play_history (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references public.profiles(id),
  track_id  uuid not null references public.tracks(id),
  played_at timestamptz not null default now()
);

create table public.followed_artists (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id),
  artist_id   uuid not null references public.artists(id),
  followed_at timestamptz not null default now()
);

-- Storage: бакет avatars (не публичный).
-- RLS на момент снимка выключен на всех таблицах.
