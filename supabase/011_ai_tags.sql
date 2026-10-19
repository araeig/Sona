alter table public.tracks
  add column mood_tags text[] not null default '{}',
  add column ai_genre text;

create index tracks_mood_tags_idx on public.tracks using gin (mood_tags);

notify pgrst, 'reload schema';
