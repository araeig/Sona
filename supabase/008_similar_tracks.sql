create or replace function public.similar_tracks(p_track_id uuid, p_limit int default 10)
returns setof public.tracks
language sql
stable
set search_path = public, extensions
as $$
  select t.*
  from public.track_embeddings e
  join public.tracks t on t.id = e.track_id
  where e.track_id <> p_track_id
  order by e.embedding <=> (
    select embedding from public.track_embeddings where track_id = p_track_id
  )
  limit p_limit;
$$;

grant execute on function public.similar_tracks(uuid, int) to authenticated;

notify pgrst, 'reload schema';
