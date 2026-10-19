alter table public.tracks
  add column ai_status text not null default 'pending'
  check (ai_status in ('pending', 'processing', 'done', 'error'));

create table public.track_embeddings (
  track_id   uuid primary key references public.tracks(id) on delete cascade,
  embedding  extensions.vector(512) not null,
  model      text not null,
  created_at timestamptz not null default now()
);

create index track_embeddings_hnsw_idx
  on public.track_embeddings
  using hnsw (embedding extensions.vector_cosine_ops);

alter table public.track_embeddings enable row level security;

create policy "catalog read" on public.track_embeddings
  for select to authenticated using (true);

notify pgrst, 'reload schema';
