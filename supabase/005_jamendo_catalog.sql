delete from public.playlist_tracks;
delete from public.liked_tracks;
delete from public.play_history;
delete from public.followed_artists;
delete from public.artist_genres;
delete from public.tracks;
delete from public.artists;
delete from public.genres;

alter table public.artists add column jamendo_id text unique;

alter table public.tracks
  add column jamendo_id   text unique,
  add column jamendo_tags text[],
  add column license_url  text;

alter table public.genres add constraint genres_name_key unique (name);

notify pgrst, 'reload schema';
