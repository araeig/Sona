-- 002_enable_pgvector.sql
-- Включает pgvector: тип vector и поиск похожих векторов.
-- Таблицы не меняются, NOTIFY не нужен.

create extension if not exists vector with schema extensions;
