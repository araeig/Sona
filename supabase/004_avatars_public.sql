-- 004_avatars_public.sql
-- Делает бакет avatars публичным: приложение показывает аватарки через getPublicUrl,
-- а такие ссылки открываются только для публичных бакетов.
-- Загружать и менять файлы по-прежнему могут только вошедшие пользователи.

update storage.buckets set public = true where id = 'avatars';
