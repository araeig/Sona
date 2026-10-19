create or replace function public.recommend_for_user(p_limit int default 20)
returns setof public.tracks
language plpgsql
stable
set search_path = public, extensions
as $$
declare
  v_user uuid := auth.uid();
  v_events int;
  v_taste vector(512);
begin
  select count(*) into v_events
  from track_events
  where user_id = v_user;

  if v_events >= 5 then
    select array_agg(w.value order by w.ord)::vector(512) into v_taste
    from (
      select dims.ord, sum(ev.weight * dims.value) as value
      from (
        select
          e.track_id,
          case e.event_type when 'like' then 2.0 when 'play' then 1.0 else -1.0 end
            * power(0.5, extract(epoch from now() - e.created_at) / 86400 / 14) as weight
        from track_events e
        where e.user_id = v_user
      ) ev
      join track_embeddings te on te.track_id = ev.track_id
      cross join lateral unnest(te.embedding::real[]) with ordinality as dims(value, ord)
      group by dims.ord
    ) w;
  end if;

  if v_taste is null then
    return query
      select t.*
      from tracks t
      order by t.play_count desc, t.created_at desc
      limit p_limit;
    return;
  end if;

  return query
    select t.*
    from track_embeddings te
    join tracks t on t.id = te.track_id
    where te.track_id not in (
      select track_id from track_events
      where user_id = v_user and created_at > now() - interval '3 days'
    )
    order by te.embedding <=> v_taste
    limit p_limit;
end;
$$;

grant execute on function public.recommend_for_user(int) to authenticated;

notify pgrst, 'reload schema';
