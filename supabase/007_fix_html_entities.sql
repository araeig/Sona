update public.artists
set name = replace(name, '&amp;', '&')
where name like '%&amp;%';
