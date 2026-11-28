-- =====================================================================
-- Matek-kaland v1.7.1 – Levél a Mestertől + „Új nevet kér a társ”
-- Futtatás: Supabase → SQL Editor → New query → beillesztés → Run. Többször is lefuttatható.
-- Semmit nem töröl és nem módosít: egy új tábla (messages) és három diák-függvény.
-- =====================================================================

create table if not exists public.messages(
  id bigserial primary key,
  student_id uuid not null references public.students(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  kind text not null default 'msg' check (kind in ('msg','pet_rename')),
  body text,                         -- a levél, ill. átnevezésnél a Mester (nem kötelező) üzenete
  pet_id text,                       -- átnevezésnél: melyik társ
  pet_name text,                     -- átnevezésnél: a kifogásolt név (csak a tanár látja)
  new_name text,                     -- átnevezésnél: amit a diák végül adott
  created_at timestamptz not null default now(),
  seen_at timestamptz,               -- a diák megkapta
  done_at timestamptz                -- átnevezésnél: a diák új nevet adott
);
create index if not exists messages_student_idx on public.messages(student_id, created_at desc);

alter table public.messages enable row level security;
revoke all on public.messages from anon, authenticated;
grant select, insert, delete on public.messages to authenticated;
grant usage, select on sequence public.messages_id_seq to authenticated;

drop policy if exists messages_own on public.messages;
create policy messages_own on public.messages for all to authenticated
  using (public.owns_class(class_id))
  with check (public.owns_class(class_id) and public.owns_student(student_id));

-- a diák lekéri az új leveleit
create or replace function public.student_msgs(p_token uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token);
begin
  return coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'kind', m.kind, 'body', m.body, 'pet_id', m.pet_id) order by m.created_at)
          from public.messages m where m.student_id = sid and m.seen_at is null), '[]'::jsonb);
end $$;

-- a diák nyugtázza, hogy megkapta
create or replace function public.student_msg_ack(p_token uuid, p_ids bigint[]) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token);
begin
  update public.messages set seen_at = now() where student_id = sid and id = any(p_ids) and seen_at is null;
  return jsonb_build_object('ok', true);
end $$;

-- a diák új nevet adott a társának
create or replace function public.student_pet_renamed(p_token uuid, p_id bigint, p_name text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token);
begin
  update public.messages set done_at = now(), new_name = left(p_name, 16), seen_at = coalesce(seen_at, now())
   where student_id = sid and id = p_id and kind = 'pet_rename' and done_at is null;
  return jsonb_build_object('ok', true);
end $$;

revoke execute on function public.student_msgs(uuid), public.student_msg_ack(uuid, bigint[]), public.student_pet_renamed(uuid, bigint, text) from public;
grant execute on function public.student_msgs(uuid), public.student_msg_ack(uuid, bigint[]), public.student_pet_renamed(uuid, bigint, text) to anon, authenticated;
