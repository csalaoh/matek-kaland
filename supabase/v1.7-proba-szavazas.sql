-- =====================================================================
-- Matek-kaland v1.7 – Próba-szabályok, egyedi tárgyak, szavazás
-- Futtatás: Supabase → SQL Editor → New query → beillesztés → Run. Többször is lefuttatható.
-- Semmit nem töröl. A régi, dupla jegyeket nem törli, csak „ismétlés”-nek jelöli.
-- =====================================================================

-- 1) PRÓBA ----------------------------------------------------------------
-- hp: az ellenfél életereje a próba indulásakor (a v1.7 előtti próbáknál üres: 4-es 120, 5-ös 200)
-- repeat: ugyanabból az altémából már volt ilyen vagy jobb jegy → nem számít
alter table public.trials add column if not exists hp int;
alter table public.trials add column if not exists repeat boolean not null default false;

-- a régi duplák jelölése (ha egy altémában több győzelem van, csak a legelső legjobb számít)
update public.trials t set repeat = true
 where t.won and not t.repeat and exists(
   select 1 from public.trials o
    where o.student_id = t.student_id and o.topic = t.topic and o.won and o.id <> t.id and o.grade >= t.grade
      and (o.finished_at < t.finished_at or (o.finished_at = t.finished_at and o.id < t.id)));

-- indítás: a tanár által nyitott altémából; 4-es naponta 2×, 5-ös hetente 3×; ha már megvan a jegy (vagy jobb), nincs több
create or replace function public.trial_start(p_token uuid, p_topic text, p_boss text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); n int; tid uuid; cfg jsonb; best int;
begin
  if p_boss not in ('t4','t5') then raise exception 'bad_boss'; end if;
  select k.config into cfg from public.students st join public.classes k on k.id = st.class_id where st.id = sid;
  if jsonb_typeof(cfg->'trial_topics') = 'array' and not ((cfg->'trial_topics') ? p_topic) then raise exception 'not_graded'; end if;
  select max(grade) into best from public.trials where student_id = sid and topic = p_topic and won and not repeat;
  if best is not null and best >= (case p_boss when 't5' then 5 else 4 end) then raise exception 'already_done'; end if;
  if p_boss = 't4' then
    select count(*) into n from public.trials where student_id = sid and topic = p_topic and boss = 't4' and day = public.mk_today();
    if n >= 2 then raise exception 'no_tries'; end if;
  else
    select count(*) into n from public.trials where student_id = sid and topic = p_topic and boss = 't5'
       and day >= date_trunc('week', public.mk_today())::date;
    if n >= 3 then raise exception 'no_tries'; end if;
  end if;
  insert into public.trials(student_id, topic, boss, day, hp)
  values (sid, left(p_topic,20), p_boss, public.mk_today(), case p_boss when 't5' then 280 else 140 end) returning id into tid;
  return tid;
end $$;

-- befejezés: ha ugyanabból az altémából már van ilyen vagy jobb jegy, a győzelem „ismétlés”, jegyet nem ad
create or replace function public.trial_end(p_token uuid, p_trial uuid, p_won boolean, p_log jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token);
begin
  update public.trials t set finished_at = now(), won = p_won,
         grade = case when p_won then (case t.boss when 't5' then 5 else 4 end) end,
         repeat = p_won and exists(select 1 from public.trials o where o.student_id = sid and o.topic = t.topic and o.won and not o.repeat
                                    and o.id <> t.id and o.grade >= (case t.boss when 't5' then 5 else 4 end)),
         log = p_log
   where t.id = p_trial and t.student_id = sid and t.finished_at is null;
  return public.mk_payload(sid);
end $$;

-- 2) EGYEDI TÁRGYAK (osztályonként egyetlen példány) -------------------------
create table if not exists public.uniques(
  class_id uuid not null references public.classes(id) on delete cascade,
  item text not null,
  student_id uuid not null references public.students(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  primary key(class_id, item)
);
alter table public.uniques enable row level security;
revoke all on public.uniques from anon, authenticated;
grant select on public.uniques to authenticated;
drop policy if exists uniques_own on public.uniques;
create policy uniques_own on public.uniques for select to authenticated using (public.owns_class(class_id));

create or replace function public.student_claim_unique(p_token uuid, p_item text) returns boolean
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); cid uuid; n int;
begin
  select class_id into cid from public.students where id = sid;
  insert into public.uniques(class_id, item, student_id) values (cid, left(p_item, 40), sid) on conflict do nothing;
  get diagnostics n = row_count;
  return n > 0;
end $$;

-- 3) amit a diák a szinkron után visszakap: 5-ös próbálkozások hetente, jegyek ismétlés nélkül, foglalt egyedi tárgyak
create or replace function public.mk_payload(sid uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'student', jsonb_build_object('id', st.id, 'nick', st.nick, 'class', k.name),
    'config', k.config,
    'state', st.state,
    'state_at', st.state_at,
    'coupons', coalesce((select jsonb_agg(jsonb_build_object('cid', c.cid, 'redeemed_at', c.redeemed_at))
                          from public.coupons c where c.student_id = st.id), '[]'::jsonb),
    'tries', coalesce((select jsonb_object_agg(x.topic || ':' || x.boss, x.n)
                        from (select t.topic, t.boss, count(*) n from public.trials t
                              where t.student_id = st.id
                                and ((t.boss = 't4' and t.day = public.mk_today())
                                  or (t.boss = 't5' and t.day >= date_trunc('week', public.mk_today())::date))
                              group by 1,2) x), '{}'::jsonb),
    'grades', coalesce((select jsonb_agg(jsonb_build_object('grade', t.grade, 'topic', t.topic, 'boss', t.boss, 'at', t.finished_at) order by t.finished_at)
                         from public.trials t where t.student_id = st.id and t.won and not t.repeat), '[]'::jsonb),
    'uniques', coalesce((select jsonb_agg(jsonb_build_object('item', u.item, 'mine', u.student_id = st.id))
                         from public.uniques u where u.class_id = st.class_id), '[]'::jsonb)
  )
  from public.students st join public.classes k on k.id = st.class_id
  where st.id = sid
$$;

-- 4) SZAVAZÁS ------------------------------------------------------------------
-- fázisok: javaslat (a diákok javasolhatnak, a tanár jóváhagyja) → szavazas → lezart (eredmény)
create table if not exists public.polls(
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null,
  question text not null default '',
  phase text not null default 'javaslat' check (phase in ('javaslat','szavazas','lezart')),
  votes_per int not null default 2 check (votes_per between 1 and 5),
  allow_propose boolean not null default true,
  created_at timestamptz not null default now(),
  closed_at timestamptz
);
create table if not exists public.poll_options(
  id bigserial primary key,
  poll_id uuid not null references public.polls(id) on delete cascade,
  label text not null,
  student_id uuid references public.students(id) on delete set null,   -- üres: a tanár vette fel
  status text not null default 'var' check (status in ('var','ok','elutasitva')),
  created_at timestamptz not null default now()
);
create table if not exists public.poll_votes(
  poll_id uuid not null references public.polls(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  option_id bigint not null references public.poll_options(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(poll_id, student_id, option_id)
);
alter table public.polls enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes enable row level security;
revoke all on public.polls, public.poll_options, public.poll_votes from anon, authenticated;
grant select, insert, update, delete on public.polls, public.poll_options to authenticated;
grant select on public.poll_votes to authenticated;
grant usage on sequence public.poll_options_id_seq to authenticated;
drop policy if exists polls_own on public.polls;
create policy polls_own on public.polls for all to authenticated using (public.owns_class(class_id)) with check (public.owns_class(class_id));
drop policy if exists poll_options_own on public.poll_options;
create policy poll_options_own on public.poll_options for all to authenticated
  using (exists(select 1 from public.polls p where p.id = poll_id and public.owns_class(p.class_id)))
  with check (exists(select 1 from public.polls p where p.id = poll_id and public.owns_class(p.class_id)));
drop policy if exists poll_votes_own on public.poll_votes;
create policy poll_votes_own on public.poll_votes for select to authenticated
  using (exists(select 1 from public.polls p where p.id = poll_id and public.owns_class(p.class_id)));

-- a diák szavazásai (a lezárt szavazásoknál 14 napig az eredménnyel; a statisztikán kívüli fiókok szavazata nem számít)
create or replace function public.student_polls(p_token uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); cid uuid;
begin
  select class_id into cid from public.students where id = sid;
  return coalesce((select jsonb_agg(jsonb_build_object(
      'id', p.id, 'title', p.title, 'question', p.question, 'phase', p.phase, 'votes_per', p.votes_per,
      'allow_propose', p.allow_propose, 'closed_at', p.closed_at,
      'options', coalesce((select jsonb_agg(jsonb_build_object('id', o.id, 'label', o.label, 'mine', coalesce(o.student_id = sid, false),
                   'n', case when p.phase = 'lezart' then (select count(*) from public.poll_votes v join public.students s2 on s2.id = v.student_id
                                                           where v.option_id = o.id and s2.in_stats) end) order by o.id)
                   from public.poll_options o where o.poll_id = p.id and o.status = 'ok'), '[]'::jsonb),
      'my_proposal', (select jsonb_build_object('id', o.id, 'label', o.label, 'status', o.status)
                      from public.poll_options o where o.poll_id = p.id and o.student_id = sid order by o.id desc limit 1),
      'my_votes', coalesce((select jsonb_agg(v.option_id) from public.poll_votes v where v.poll_id = p.id and v.student_id = sid), '[]'::jsonb)
    ) order by p.created_at desc)
    from public.polls p where p.class_id = cid and (p.phase <> 'lezart' or p.closed_at > now() - interval '14 days')), '[]'::jsonb);
end $$;

-- javaslat: szavazásonként egy (amíg a tanár el nem bírálja, átírható; elutasítás után újat adhat)
create or replace function public.student_poll_propose(p_token uuid, p_poll uuid, p_label text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); lbl text; p public.polls; mine public.poll_options;
begin
  lbl := btrim(regexp_replace(coalesce(p_label, ''), '\s+', ' ', 'g'));
  if length(lbl) < 2 or length(lbl) > 40 then raise exception 'bad_label'; end if;
  select * into p from public.polls where id = p_poll and class_id = (select class_id from public.students where id = sid);
  if p.id is null or p.phase <> 'javaslat' or not p.allow_propose then raise exception 'closed'; end if;
  select * into mine from public.poll_options where poll_id = p_poll and student_id = sid and status in ('var','ok') order by id desc limit 1;
  if mine.status = 'ok' then raise exception 'already'; end if;
  if exists(select 1 from public.poll_options where poll_id = p_poll and status in ('var','ok') and lower(label) = lower(lbl)
            and id is distinct from mine.id) then raise exception 'duplicate'; end if;
  if mine.id is not null then update public.poll_options set label = lbl, created_at = now() where id = mine.id;
  else insert into public.poll_options(poll_id, label, student_id) values (p_poll, lbl, sid); end if;
  return public.student_polls(p_token);
end $$;

-- szavazat: legfeljebb votes_per különböző lehetőségre; a lezárásig módosítható
create or replace function public.student_poll_vote(p_token uuid, p_poll uuid, p_options bigint[]) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); p public.polls; ids bigint[];
begin
  select * into p from public.polls where id = p_poll and class_id = (select class_id from public.students where id = sid);
  if p.id is null or p.phase <> 'szavazas' then raise exception 'closed'; end if;
  select array_agg(distinct x) into ids from unnest(coalesce(p_options, '{}')) x;
  if coalesce(array_length(ids, 1), 0) > p.votes_per then raise exception 'too_many'; end if;
  if exists(select 1 from unnest(coalesce(ids, '{}')) x where not exists(
            select 1 from public.poll_options o where o.id = x and o.poll_id = p_poll and o.status = 'ok')) then raise exception 'bad_option'; end if;
  delete from public.poll_votes where poll_id = p_poll and student_id = sid;
  insert into public.poll_votes(poll_id, student_id, option_id) select p_poll, sid, x from unnest(coalesce(ids, '{}')) x;
  return public.student_polls(p_token);
end $$;

revoke execute on function public.student_claim_unique(uuid, text), public.student_polls(uuid),
  public.student_poll_propose(uuid, uuid, text), public.student_poll_vote(uuid, uuid, bigint[]) from public;
grant execute on function public.student_claim_unique(uuid, text), public.student_polls(uuid),
  public.student_poll_propose(uuid, uuid, text), public.student_poll_vote(uuid, uuid, bigint[]) to anon, authenticated;

-- 5) Tanári összesítő: a jegyeknél az ellenfél életereje és az „ismétlés” jelölés is jön, a diákoknál a felszerelés

create or replace function public.teacher_class_stats(p_class uuid, p_since timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'students', coalesce((select jsonb_agg(jsonb_build_object(
        'id', st.id, 'nick', st.nick, 'active', st.active, 'in_stats', st.in_stats, 'last_seen', st.last_seen, 'locked', st.locked_until > now(),
        'clvl', st.state->'clvl', 'xp', st.state->'xp', 'gold', st.state->'gold', 'cls', st.state->'cls', 'prog', st.state->'prog', 'pets', st.state->'pets', 'pet_on', st.state->'petOn', 'lib', st.state->'lib', 'gear', st.state->'gear',
        'topic', st.state->'topic', 'level', st.state->'level', 'max', st.state->'max',
        'n', (select count(*) from public.events e where e.student_id = st.id and e.ts >= p_since),
        'ok', (select count(*) from public.events e where e.student_id = st.id and e.ts >= p_since and e.status = 'correct'),
        'days', (select count(distinct (e.ts at time zone 'Europe/Budapest')::date) from public.events e where e.student_id = st.id and e.ts >= p_since),
        'grades', coalesce((select jsonb_agg(jsonb_build_object('grade', t.grade, 'topic', t.topic, 'at', t.finished_at, 'id', t.id,
                              'boss', t.boss, 'started', t.started_at, 'hp', t.hp, 'repeat', t.repeat,
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
