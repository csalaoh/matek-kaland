-- =====================================================================
-- Matek-kaland v1.0 – visszajelzések (🐞 gomb)
-- Futtatás: Supabase → SQL Editor → New query → beilleszt → Run.
-- Egyszer kell lefuttatni; többször is lefuttatható, adatot nem töröl.
-- =====================================================================

create table if not exists public.feedback(
  id bigserial primary key,
  student_id uuid references public.students(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  nick text,
  kind text not null check (kind in ('bug','idea','like')),
  body text not null,
  app_version text,
  screen text,
  device text,
  status text not null default 'new' check (status in ('new','planned','done','rejected')),
  created_at timestamptz not null default now()
);
create index if not exists feedback_class_ts_idx on public.feedback(class_id, created_at desc);

alter table public.feedback enable row level security;
revoke all on public.feedback from anon, authenticated;
grant select, delete on public.feedback to authenticated;
grant update (status) on public.feedback to authenticated;
grant usage, select on sequence public.feedback_id_seq to authenticated;

drop policy if exists feedback_own on public.feedback;
create policy feedback_own on public.feedback for all to authenticated
  using (public.owns_class(class_id)) with check (public.owns_class(class_id));

-- a diák ezzel küld (bejelentkezve); naponta legfeljebb 15 bejelentés diákonként
create or replace function public.student_feedback(p_token uuid, p_kind text, p_body text,
  p_version text default '', p_screen text default '', p_device text default '')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); st public.students; n int;
begin
  if p_kind not in ('bug','idea','like') then return jsonb_build_object('error','bad_kind'); end if;
  if length(trim(coalesce(p_body,''))) < 2 then return jsonb_build_object('error','empty'); end if;
  select count(*) into n from public.feedback
   where student_id = sid and (created_at at time zone 'Europe/Budapest')::date = public.mk_today();
  if n >= 15 then return jsonb_build_object('error','too_many'); end if;
  select * into st from public.students where id = sid;
  insert into public.feedback(student_id, class_id, nick, kind, body, app_version, screen, device)
  values (sid, st.class_id, st.nick, p_kind, left(trim(p_body),1000), left(p_version,20), left(p_screen,60), left(p_device,200));
  return jsonb_build_object('ok', true);
end $$;

revoke execute on function public.student_feedback(uuid, text, text, text, text, text) from public;
grant execute on function public.student_feedback(uuid, text, text, text, text, text) to anon, authenticated;
