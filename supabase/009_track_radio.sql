create or replace function public.track_radio(
  p_track_id uuid,
  p_exclude uuid[] default '{}',
  p_limit int default 10
)
returns setof public.tracks
language sql
volatile
set search_path = public, extensions
as $$
  with candidates as (
    select
      e.track_id,
      t.artist_id,
      e.embedding <=> (
        select embedding from public.track_embeddings where track_id = p_track_id
      ) as distance
    from public.track_embeddings e
    join public.tracks t on t.id = e.track_id
    where e.track_id <> p_track_id
      and not (e.track_id = any(p_exclude))
    order by distance
    limit 30
  ),
  per_artist as (
    select *, row_number() over (partition by artist_id order by distance) as artist_rank
    from candidates
  ),
  picked as (
    select track_id, distance
    from per_artist
    where artist_rank <= 2
    order by random()
    limit p_limit
  )
  select t.*
  from picked p
  join public.tracks t on t.id = p.track_id
  order by p.distance;
$$;

grant execute on function public.track_radio(uuid, uuid[], int) to authenticated;

notify pgrst, 'reload schema';
