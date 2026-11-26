-- Matek-kaland v1.4.2 – a dupla visszajelzések kiszűrése
-- Ha ugyanaz a diák ugyanazt a szöveget 30 percen belül újra elküldi
-- (pl. akadozó net miatti újraküldés), nem mentjük el még egyszer, de "ok"-t válaszolunk.
-- Futtatás: Supabase → SQL Editor → beillesztés → Run. Többször is lefuttatható.

create or replace function public.student_feedback(p_token uuid, p_kind text, p_body text,
  p_version text default '', p_screen text default '', p_device text default '')
returns jsonb language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); st public.students; n int;
begin
  if p_kind not in ('bug','idea','like') then return jsonb_build_object('error','bad_kind'); end if;
  if length(trim(coalesce(p_body,''))) < 2 then return jsonb_build_object('error','empty'); end if;
  -- v1.4.2: ugyanaz a szöveg 30 percen belül → már megvan, nem mentjük újra
  if exists (select 1 from public.feedback
              where student_id = sid and kind = p_kind and body = left(trim(p_body),1000)
                and created_at > now() - interval '30 minutes') then
    return jsonb_build_object('ok', true, 'dup', true);
  end if;
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

-- A már bent lévő duplikátumok törlése (a korábbit tartjuk meg):
delete from public.feedback f
 using public.feedback g
 where f.student_id = g.student_id and f.kind = g.kind and f.body = g.body
   and f.id > g.id and f.created_at - g.created_at < interval '30 minutes';
