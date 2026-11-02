-- Ejecutar una sola vez en Supabase SQL Editor.
-- NOTA: después de crear el usuario en Authentication, agregue su UUID a portal_admins.
create extension if not exists pgcrypto;
create table if not exists public.portal_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.portal_reports (
  id uuid primary key default gen_random_uuid(),
  token text unique not null check (length(token)=64 and token ~ '^[a-f0-9]+$'),
  number text not null check (length(number) between 1 and 120),
  identification text not null check (length(identification) between 1 and 350),
  issuer text not null check (length(issuer) between 1 and 150),
  published_at timestamptz not null,
  file_path text unique not null,
  status text not null default 'active' check (status in ('active','inactive')),
  created_at timestamptz not null default now()
);
create index if not exists portal_reports_number_idx on public.portal_reports(number);
alter table public.portal_admins enable row level security;
alter table public.portal_reports enable row level security;
-- Los administradores solo pueden ver su propia asignación. El acceso público no recibe la tabla.
create policy "admin self read" on public.portal_admins for select to authenticated using (user_id=auth.uid());
-- Función de verificación para policies de ambas tablas y Storage.
create or replace function public.is_portal_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.portal_admins where user_id=(select auth.uid()));
$$;
revoke all on function public.is_portal_admin() from public;
grant execute on function public.is_portal_admin() to authenticated;
create policy "admin reports select" on public.portal_reports for select to authenticated using (public.is_portal_admin());
create policy "admin reports insert" on public.portal_reports for insert to authenticated with check (public.is_portal_admin());
create policy "admin reports update" on public.portal_reports for update to authenticated using (public.is_portal_admin()) with check (public.is_portal_admin());
-- Sin borrado público ni borrado por administrador (se conserva la trazabilidad).
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('report-pdfs','report-pdfs',false,20971520,array['application/pdf'])
on conflict (id) do update set public=false,file_size_limit=20971520,allowed_mime_types=array['application/pdf'];
create policy "admins upload reports" on storage.objects for insert to authenticated
with check (bucket_id='report-pdfs' and public.is_portal_admin());
-- Búsqueda pública por número, devuelve un token solamente de informes activos.
-- Los números pueden ser enumerados. Si necesita datos privados, elimine esta función.
create or replace function public.find_public_report(p_number text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare t text;
begin
 if length(p_number)>120 or length(p_number)<1 then return '{}'::jsonb; end if;
 select token into t from public.portal_reports
 where number=p_number and status='active' order by created_at desc limit 1;
 if t is null then return '{}'::jsonb; end if;
 return jsonb_build_object('token',t);
end $$;
revoke all on function public.find_public_report(text) from public;
grant execute on function public.find_public_report(text) to anon,authenticated;
-- DESPUÉS: ejecute con el UUID del usuario creado en Authentication:
-- insert into public.portal_admins(user_id) values ('UUID-DEL-USUARIO');
