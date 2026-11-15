-- PARIS – 20 CLANS · prototype de pré-réservation par e-mail
-- À coller dans Supabase > SQL Editor, puis « Run ».

create table if not exists public.reservations (
  id             bigint generated always as identity primary key,
  email          text        not null,
  arrondissement smallint    not null check (arrondissement between 1 and 20),
  created_at     timestamptz not null default now(),
  constraint email_valide check (
    length(email) <= 254 and email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  )
);

-- Un e-mail = une seule réservation, tous arrondissements confondus.
create unique index if not exists reservations_email_unique
  on public.reservations (lower(email));

-- Personne ne peut lire les e-mails depuis le site : écriture seule.
alter table public.reservations enable row level security;

drop policy if exists "reservation publique" on public.reservations;
create policy "reservation publique" on public.reservations
  for insert to anon with check (true);

revoke all on public.reservations from anon;
grant insert (email, arrondissement) on public.reservations to anon;

-- Le site ne voit que les totaux par arrondissement, jamais les e-mails.
create or replace function public.compteurs()
returns table (arrondissement smallint, total bigint)
language sql security definer set search_path = public as $$
  select arrondissement, count(*) from public.reservations group by arrondissement
$$;

revoke all on function public.compteurs() from public;
grant execute on function public.compteurs() to anon;
