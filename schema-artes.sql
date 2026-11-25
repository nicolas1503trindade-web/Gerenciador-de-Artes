-- Biblioteca de Artes do Postflow / Omar Contadores
-- Execute este arquivo no Supabase > SQL Editor > New query > Run.
create extension if not exists pgcrypto;

create table if not exists public.art_assets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null default 'Outros',
  status text not null default 'Em criação',
  format text,
  campaign text,
  owner text,
  art_date date,
  description text,
  file_path text not null,
  file_name text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.art_assets enable row level security;

drop policy if exists "Equipe visualiza artes" on public.art_assets;
create policy "Equipe visualiza artes" on public.art_assets
for select to authenticated using (true);

drop policy if exists "Equipe cadastra artes" on public.art_assets;
create policy "Equipe cadastra artes" on public.art_assets
for insert to authenticated with check (auth.uid() = created_by);

drop policy if exists "Equipe edita artes" on public.art_assets;
create policy "Equipe edita artes" on public.art_assets
for update to authenticated using (true) with check (true);

drop policy if exists "Equipe exclui artes" on public.art_assets;
create policy "Equipe exclui artes" on public.art_assets
for delete to authenticated using (true);

-- Bucket privado: os arquivos só são acessíveis por usuários autenticados.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('artes', 'artes', false, 52428800, array[
 'image/png','image/jpeg','image/webp','image/gif','image/svg+xml',
 'application/pdf','application/postscript','application/illustrator',
 'video/mp4','application/octet-stream'
])
on conflict (id) do update set public=false;

drop policy if exists "Equipe lê arquivos de artes" on storage.objects;
create policy "Equipe lê arquivos de artes" on storage.objects
for select to authenticated using (bucket_id = 'artes');

drop policy if exists "Equipe envia arquivos de artes" on storage.objects;
create policy "Equipe envia arquivos de artes" on storage.objects
for insert to authenticated with check (bucket_id = 'artes' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Equipe atualiza arquivos de artes" on storage.objects;
create policy "Equipe atualiza arquivos de artes" on storage.objects
for update to authenticated using (bucket_id = 'artes') with check (bucket_id = 'artes');

drop policy if exists "Equipe remove arquivos de artes" on storage.objects;
create policy "Equipe remove arquivos de artes" on storage.objects
for delete to authenticated using (bucket_id = 'artes');

alter table public.art_assets replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.art_assets;
exception when duplicate_object then null;
end $$;
