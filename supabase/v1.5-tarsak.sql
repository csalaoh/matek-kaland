-- =====================================================================
-- Matek-kaland v1.5 – Társak (petek) a tanári felületen
-- Futtatás: Supabase → SQL Editor → New query → beilleszt → Run. Többször is futtatható.
-- Semmit nem töröl és nem módosít: csak a tanári összesítő adja vissza a diákok társait is (név, fajta, fokozat).
-- =====================================================================

-- osztály-áttekintés és hibatérkép egy hívásban (a Supabase 1000 soros limitje miatt a szerveren összesítünk)
create or replace function public.teacher_class_stats(p_class uuid, p_since timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'students', coalesce((select jsonb_agg(jsonb_build_object(
        'id', st.id, 'nick', st.nick, 'active', st.active, 'in_stats', st.in_stats, 'last_seen', st.last_seen, 'locked', st.locked_until > now(),
        'clvl', st.state->'clvl', 'xp', st.state->'xp', 'gold', st.state->'gold', 'cls', st.state->'cls', 'prog', st.state->'prog', 'pets', st.state->'pets', 'pet_on', st.state->'petOn',
        'topic', st.state->'topic', 'level', st.state->'level', 'max', st.state->'max',
        'n', (select count(*) from public.events e where e.student_id = st.id and e.ts >= p_since),
        'ok', (select count(*) from public.events e where e.student_id = st.id and e.ts >= p_since and e.status = 'correct'),
        'days', (select count(distinct (e.ts at time zone 'Europe/Budapest')::date) from public.events e where e.student_id = st.id and e.ts >= p_since),
        'grades', coalesce((select jsonb_agg(jsonb_build_object('grade', t.grade, 'topic', t.topic, 'at', t.finished_at, 'id', t.id,
                              'boss', t.boss, 'started', t.started_at,
                              'log_n', case when jsonb_typeof(t.log) = 'array' then jsonb_array_length(t.log) else 0 end,
                              'log_dmg', (select coalesce(sum(case x->>'status' when 'correct' then a.d when 'partial' then round(a.d / 2.0) else 0 end), 0)
                                          from jsonb_array_elements(case when jsonb_typeof(t.log) = 'array' then t.log else '[]'::jsonb end) x
                                          cross join lateral (select case x->>'level' when '1' then 10 when '2' then 20 when '3' then 35 else 0 end as d) a),
                              'ev_n', (select count(*) from public.events e where e.student_id = st.id and e.mode = 'trial'
                                       and e.ts between t.started_at - interval '2 minutes' and t.finished_at + interval '2 minutes')
                            ) order by t.finished_at)
                            from public.trials t where t.student_id = st.id and t.won), '[]'::jsonb)
      ) order by st.nick_key) from public.students st where st.class_id = p_class), '[]'::jsonb),
    'errors', coalesce((select jsonb_agg(x) from (
        select e.topic, e.err, count(*) n, count(distinct e.student_id) students
        from public.events e join public.students st on st.id = e.student_id
        where st.class_id = p_class and st.in_stats and e.ts >= p_since and e.status in ('wrong','partial') and e.err is not null and e.err <> ''
        group by 1,2 order by 3 desc) x), '[]'::jsonb),
    'matrix', coalesce((select jsonb_agg(x) from (
        select e.student_id, e.topic, e.err, count(*) n
        from public.events e join public.students st on st.id = e.student_id
        where st.class_id = p_class and st.in_stats and e.ts >= p_since and e.status in ('wrong','partial') and e.err is not null and e.err <> ''
        group by 1,2,3) x), '[]'::jsonb),
    'levels', coalesce((select jsonb_agg(x) from (
        select e.topic, e.level, count(*) n, count(*) filter (where e.status = 'correct') ok
        from public.events e join public.students st on st.id = e.student_id
        where st.class_id = p_class and st.in_stats and e.ts >= p_since and e.mode = 'practice'
        group by 1,2 order by 1,2) x), '[]'::jsonb),
    'coupons', coalesce((select jsonb_agg(jsonb_build_object('student_id', c.student_id, 'nick', st.nick, 'cid', c.cid, 'name', c.name, 'code', c.code,
                          'is_test', c.is_test, 'created_at', c.created_at) order by c.created_at)
        from public.coupons c join public.students st on st.id = c.student_id
        where st.class_id = p_class and st.in_stats and c.redeemed_at is null), '[]'::jsonb)
  );
end $$;
