create or replace function public.increment_play_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.tracks
  set play_count = coalesce(play_count, 0) + 1
  where id = new.track_id;
  return new;
end;
$$;

create trigger play_history_play_count
  after insert on public.play_history
  for each row execute function public.increment_play_count();

create or replace function public.update_listener_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.artists
    set listener_count = coalesce(listener_count, 0) + 1
    where id = new.artist_id;
  elsif tg_op = 'DELETE' then
    update public.artists
    set listener_count = greatest(coalesce(listener_count, 0) - 1, 0)
    where id = old.artist_id;
  end if;
  return null;
end;
$$;

create trigger followed_artists_listener_count
  after insert or delete on public.followed_artists
  for each row execute function public.update_listener_count();

update public.tracks t
set play_count = (select count(*) from public.play_history h where h.track_id = t.id);

update public.artists a
set listener_count = (select count(*) from public.followed_artists f where f.artist_id = a.id);

notify pgrst, 'reload schema';
