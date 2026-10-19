create or replace function public.search_tracks_by_embedding(
  p_embedding extensions.vector(512),
  p_limit int default 10
)
returns table (track_id uuid, similarity float)
language sql
stable
set search_path = public, extensions
as $$
  select
    e.track_id,
    1 - (e.embedding <=> p_embedding) as similarity
  from public.track_embeddings e
  order by e.embedding <=> p_embedding
  limit p_limit;
$$;

notify pgrst, 'reload schema';
