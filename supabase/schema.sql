-- =====================================================================
-- Matek-kaland – adatbázis (Supabase)
-- Futtatás: Supabase → SQL Editor → New query → beilleszt → Run.
-- Többször is lefuttatható: a meglévő adatokat nem törli.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

-- ---------- TÁBLÁK ----------
create table if not exists public.teachers(
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.classes(
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.teachers(id) on delete cascade,
  name text not null,
  config jsonb not null default '{}'::jsonb,   -- {lessons:{betus:'open',zk:'open',...}, privs:[...]}
  created_at timestamptz not null default now()
);

create table if not exists public.students(
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  nick text not null,
  nick_key text not null unique,               -- kisbetűs, szóköz nélküli becenév: ezzel lép be
  pin_hash text not null,
  fails int not null default 0,
  locked_until timestamptz,
  active boolean not null default true,
  state jsonb,                                 -- a játék teljes mentése
  state_at timestamptz,
  last_seen timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists students_class_idx on public.students(class_id);

create table if not exists public.sessions(
  token uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_used timestamptz not null default now()
);

create table if not exists public.events(
  id bigserial primary key,
  student_id uuid not null references public.students(id) on delete cascade,
  ts timestamptz not null,
  topic text, mode text, level int, kind text,
  status text, err text, hint int, half boolean,
  task text, answer text
);
create index if not exists events_student_ts_idx on public.events(student_id, ts desc);

create table if not exists public.trials(
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  topic text not null,
  boss text not null,                          -- t4 | t5
  day date not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  won boolean,
  grade int,
  log jsonb
);
create index if not exists trials_student_day_idx on public.trials(student_id, day);

create table if not exists public.coupons(
  student_id uuid not null references public.students(id) on delete cascade,
  cid text not null,
  priv_id text, name text, code text,
  is_test boolean not null default false,
  created_at timestamptz not null default now(),
  redeemed_at timestamptz,
  primary key(student_id, cid)
);

-- ---------- JOGOSULTSÁGOK ----------
alter table public.teachers enable row level security;
alter table public.classes  enable row level security;
alter table public.students enable row level security;
alter table public.sessions enable row level security;
alter table public.events   enable row level security;
alter table public.trials   enable row level security;
alter table public.coupons  enable row level security;

revoke all on public.teachers, public.classes, public.students, public.sessions, public.events, public.trials, public.coupons from anon, authenticated;
grant select on public.teachers to authenticated;
grant select, insert, update, delete on public.classes to authenticated;
grant select (id, class_id, nick, nick_key, fails, locked_until, active, state, state_at, last_seen, created_at) on public.students to authenticated;
grant update (active, class_id) on public.students to authenticated;
grant delete on public.students to authenticated;
grant select on public.events, public.trials to authenticated;
grant select on public.coupons to authenticated;
grant update (redeemed_at) on public.coupons to authenticated;

create or replace function public.is_teacher() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.teachers t where t.id = auth.uid())
$$;
create or replace function public.owns_class(c uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.classes k where k.id = c and k.teacher_id = auth.uid())
$$;
create or replace function public.owns_student(s uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.students st join public.classes k on k.id = st.class_id
                where st.id = s and k.teacher_id = auth.uid())
$$;

drop policy if exists teachers_self on public.teachers;
create policy teachers_self on public.teachers for select to authenticated using (id = auth.uid());
drop policy if exists classes_own on public.classes;
create policy classes_own on public.classes for all to authenticated
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid() and public.is_teacher());
drop policy if exists students_own on public.students;
create policy students_own on public.students for all to authenticated
  using (public.owns_class(class_id)) with check (public.owns_class(class_id));
drop policy if exists events_own on public.events;
create policy events_own on public.events for select to authenticated using (public.owns_student(student_id));
drop policy if exists trials_own on public.trials;
create policy trials_own on public.trials for select to authenticated using (public.owns_student(student_id));
drop policy if exists coupons_own on public.coupons;
create policy coupons_own on public.coupons for all to authenticated
  using (public.owns_student(student_id)) with check (public.owns_student(student_id));

-- ---------- SEGÉDEK ----------
create or replace function public.mk_today() returns date
language sql stable set search_path = '' as $$ select (now() at time zone 'Europe/Budapest')::date $$;

create or replace function public.mk_nick_key(n text) returns text
language sql immutable set search_path = '' as $$ select lower(regexp_replace(coalesce(n,''), '\s+', '', 'g')) $$;

create or replace function public.mk_student(p_token uuid) returns uuid
language plpgsql security definer set search_path = '' as $$
declare sid uuid;
begin
  update public.sessions s set last_used = now()
   where s.token = p_token and s.last_used > now() - interval '180 days'
   returning s.student_id into sid;
  if sid is null then raise exception 'bad_session'; end if;
  if not exists(select 1 from public.students st where st.id = sid and st.active) then raise exception 'inactive'; end if;
  update public.students st set last_seen = now() where st.id = sid;
  return sid;
end $$;

-- amit a diák a belépés / szinkron után visszakap
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
                              where t.student_id = st.id and t.day = public.mk_today() group by 1,2) x), '{}'::jsonb),
    'grades', coalesce((select jsonb_agg(jsonb_build_object('grade', t.grade, 'topic', t.topic, 'boss', t.boss, 'at', t.finished_at) order by t.finished_at)
                         from public.trials t where t.student_id = st.id and t.won), '[]'::jsonb)
  )
  from public.students st join public.classes k on k.id = st.class_id
  where st.id = sid
$$;

-- ---------- DIÁK-FÜGGVÉNYEK (anon) ----------
create or replace function public.student_login(p_nick text, p_pin text) returns jsonb
language plpgsql security definer set search_path = '' as $$
-- hibánál nem dobunk kivételt, mert az visszagörgetné a hibás próbálkozások számlálását
declare st public.students; tok uuid;
begin
  select * into st from public.students where nick_key = public.mk_nick_key(p_nick);
  if st.id is null then perform pg_sleep(0.4); return jsonb_build_object('error','bad_login'); end if;
  if st.locked_until is not null and st.locked_until > now() then return jsonb_build_object('error','locked'); end if;
  if not st.active then return jsonb_build_object('error','inactive'); end if;
  if extensions.crypt(coalesce(p_pin,''), st.pin_hash) <> st.pin_hash then
    update public.students set fails = fails + 1,
      locked_until = case when fails + 1 >= 5 then now() + interval '5 minutes' else locked_until end
      where id = st.id;
    perform pg_sleep(0.4);
    return jsonb_build_object('error','bad_login');
  end if;
  update public.students set fails = 0, locked_until = null, last_seen = now() where id = st.id;
  insert into public.sessions(student_id) values (st.id) returning token into tok;
  return public.mk_payload(st.id) || jsonb_build_object('token', tok);
end $$;

create or replace function public.student_logout(p_token uuid) returns void
language sql security definer set search_path = '' as $$ delete from public.sessions where token = p_token $$;

-- mentés + eseménynapló + új kuponok egy hívásban; vissza: config, kuponok állapota, mai próbák, jegyek
create or replace function public.student_sync(p_token uuid, p_state jsonb default null, p_events jsonb default '[]'::jsonb, p_coupons jsonb default '[]'::jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token);
begin
  if p_state is not null then
    update public.students set state = p_state, state_at = now() where id = sid;
  end if;
  insert into public.events(student_id, ts, topic, mode, level, kind, status, err, hint, half, task, answer)
  select sid, coalesce((e->>'ts')::timestamptz, now()), left(e->>'topic',20), left(e->>'mode',20), (e->>'level')::int,
         left(e->>'kind',10), left(e->>'status',20), left(e->>'err',80), (e->>'hint')::int, (e->>'half')::boolean,
         left(e->>'task',200), left(e->>'answer',200)
  from jsonb_array_elements(coalesce(p_events,'[]'::jsonb)) e
  limit 500;
  insert into public.coupons(student_id, cid, priv_id, name, code, is_test)
  select sid, left(c->>'cid',40), left(c->>'pid',40), left(c->>'name',120), left(c->>'code',10), coalesce((c->>'test')::boolean,false)
  from jsonb_array_elements(coalesce(p_coupons,'[]'::jsonb)) c
  on conflict do nothing;
  return public.mk_payload(sid);
end $$;

create or replace function public.trial_start(p_token uuid, p_topic text, p_boss text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); n int; tid uuid;
begin
  if p_boss not in ('t4','t5') then raise exception 'bad_boss'; end if;
  select count(*) into n from public.trials where student_id = sid and topic = p_topic and boss = p_boss and day = public.mk_today();
  if n >= 2 then raise exception 'no_tries'; end if;
  insert into public.trials(student_id, topic, boss, day) values (sid, left(p_topic,20), p_boss, public.mk_today()) returning id into tid;
  return tid;
end $$;

create or replace function public.trial_end(p_token uuid, p_trial uuid, p_won boolean, p_log jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token);
begin
  update public.trials set finished_at = now(), won = p_won,
         grade = case when p_won then (case boss when 't5' then 5 else 4 end) end,
         log = p_log
   where id = p_trial and student_id = sid and finished_at is null;
  return public.mk_payload(sid);
end $$;

-- ---------- TANÁRI FÜGGVÉNYEK (authenticated) ----------
create or replace function public.teacher_create_students(p_class uuid, p_nicks text[])
returns table(nick text, pin text, ok boolean, msg text)
language plpgsql security definer set search_path = '' as $$
declare n text; p text;
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  foreach n in array p_nicks loop
    n := btrim(n);
    continue when n = '';
    if length(n) > 24 then nick := n; pin := null; ok := false; msg := 'túl hosszú (max. 24 karakter)'; return next; continue; end if;
    if exists(select 1 from public.students s where s.nick_key = public.mk_nick_key(n)) then
      nick := n; pin := null; ok := false; msg := 'ez a becenév már foglalt'; return next; continue;
    end if;
    p := lpad((1000 + floor(random()*9000))::int::text, 4, '0');
    insert into public.students(class_id, nick, nick_key, pin_hash)
      values (p_class, n, public.mk_nick_key(n), extensions.crypt(p, extensions.gen_salt('bf', 8)));
    nick := n; pin := p; ok := true; msg := ''; return next;
  end loop;
end $$;

create or replace function public.teacher_reset_pin(p_student uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare p text := lpad((1000 + floor(random()*9000))::int::text, 4, '0');
begin
  if not public.owns_student(p_student) then raise exception 'forbidden'; end if;
  update public.students set pin_hash = extensions.crypt(p, extensions.gen_salt('bf', 8)), fails = 0, locked_until = null where id = p_student;
  delete from public.sessions where student_id = p_student;
  return p;
end $$;

-- osztály-áttekintés és hibatérkép egy hívásban (a Supabase 1000 soros limitje miatt a szerveren összesítünk)
create or replace function public.teacher_class_stats(p_class uuid, p_since timestamptz)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'students', coalesce((select jsonb_agg(jsonb_build_object(
        'id', st.id, 'nick', st.nick, 'active', st.active, 'last_seen', st.last_seen, 'locked', st.locked_until > now(),
        'clvl', st.state->'clvl', 'xp', st.state->'xp', 'gold', st.state->'gold', 'cls', st.state->'cls', 'prog', st.state->'prog',
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
        where st.class_id = p_class and e.ts >= p_since and e.status in ('wrong','partial') and e.err is not null and e.err <> ''
        group by 1,2 order by 3 desc) x), '[]'::jsonb),
    'matrix', coalesce((select jsonb_agg(x) from (
        select e.student_id, e.topic, e.err, count(*) n
        from public.events e join public.students st on st.id = e.student_id
        where st.class_id = p_class and e.ts >= p_since and e.status in ('wrong','partial') and e.err is not null and e.err <> ''
        group by 1,2,3) x), '[]'::jsonb),
    'levels', coalesce((select jsonb_agg(x) from (
        select e.topic, e.level, count(*) n, count(*) filter (where e.status = 'correct') ok
        from public.events e join public.students st on st.id = e.student_id
        where st.class_id = p_class and e.ts >= p_since and e.mode = 'practice'
        group by 1,2 order by 1,2) x), '[]'::jsonb),
    'coupons', coalesce((select jsonb_agg(jsonb_build_object('student_id', c.student_id, 'nick', st.nick, 'cid', c.cid, 'name', c.name, 'code', c.code,
                          'is_test', c.is_test, 'created_at', c.created_at) order by c.created_at)
        from public.coupons c join public.students st on st.id = c.student_id
        where st.class_id = p_class and c.redeemed_at is null), '[]'::jsonb)
  );
end $$;

-- tanári belépéskor hívja a dashboard: a Supabase-ben kézzel felvett felhasználó tanárként regisztrálódik
-- (a nyilvános regisztráció ki van kapcsolva, így csak az lehet tanár, akit te veszel fel)
create or replace function public.teacher_hello(p_name text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'forbidden'; end if;
  insert into public.teachers(id, name) values (auth.uid(), coalesce(p_name,'')) on conflict (id) do nothing;
  return jsonb_build_object('id', auth.uid());
end $$;

-- ---------- FÜGGVÉNYJOGOK ----------
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.student_login(text, text), public.student_logout(uuid),
  public.student_sync(uuid, jsonb, jsonb, jsonb), public.trial_start(uuid, text, text),
  public.trial_end(uuid, uuid, boolean, jsonb) to anon, authenticated;
grant execute on function public.teacher_hello(text), public.teacher_create_students(uuid, text[]), public.teacher_reset_pin(uuid),
  public.teacher_class_stats(uuid, timestamptz), public.is_teacher(), public.owns_class(uuid), public.owns_student(uuid)
  to authenticated;

-- ---------- SZÖRNYEK (motivációs rendszer, 2026-11-23) ----------
create table if not exists public.monsters(
  code text primary key,
  name text not null,
  topic text not null,             -- events.topic
  kinds text[] not null,           -- events.kind értékek, ahol a hiba elkövethető ('' = összevonás/helyettesítés)
  rule_hint text not null,
  image_path text,
  designed_by uuid references public.students(id) on delete set null
);

create table if not exists public.err_map(
  err text primary key,            -- events.err pontos szövege, vagy 'status:halfway'
  monster_code text not null references public.monsters(code)
);

alter table public.monsters enable row level security;
alter table public.err_map  enable row level security;
revoke all on public.monsters, public.err_map from anon, authenticated;
grant select on public.monsters, public.err_map to authenticated;
drop policy if exists monsters_read on public.monsters;
create policy monsters_read on public.monsters for select to authenticated using (true);
drop policy if exists err_map_read on public.err_map;
create policy err_map_read on public.err_map for select to authenticated using (true);

insert into public.monsters(code, name, topic, kinds, rule_hint) values
  ('ELO', 'Mínuszfaló',          'zk',    array['fel'],     'A zárójel előtti mínusz a zárójelben minden tag előjelét megfordítja.'),
  ('SZO', 'Felső-szorzó papóca', 'zk',    array['fel'],     'A zárójel előtti szorzóval a zárójelben minden tagot meg kell szorozni.'),
  ('KEV', 'Keverő-kígyó',        'betus', array['','fel'],  'Csak az azonos betűrészű tagok vonhatók össze.'),
  ('EGY', 'Láthatatlan Egyes',   'betus', array['','fel'],  'Az x azt jelenti: 1x. A −x pedig −1x.'),
  ('MAR', 'Maradék-moly',        'zk',    array['ki'],      'Kiemelésnél minden tagot el kell osztani a kiemelt tényezővel.'),
  ('FEL', 'Félúton-manó',        'zk',    array['ki'],      'A legnagyobb közös tényezőt emeld ki.'),
  ('NEG', 'Előjel-kísértet',     'betus', array[''],        'Negatív számot zárójelben helyettesíts be.')
on conflict (code) do update set name = excluded.name, topic = excluded.topic, kinds = excluded.kinds, rule_hint = excluded.rule_hint;

insert into public.err_map(err, monster_code) values
  ('Mínusz-tükör hiba',                 'ELO'),
  ('A szorzó nem ért el minden tagot',  'SZO'),
  ('Különnemű tagok összevonása',       'KEV'),
  ('Láthatatlan egyes',                 'EGY'),
  ('Egy tagot nem osztottál el',        'MAR'),
  ('status:halfway',                    'FEL'),
  ('Előjelhiba behelyettesítéskor',     'NEG')
on conflict (err) do update set monster_code = excluded.monster_code;


-- ---------- VISSZAJELZÉSEK (v1.0, 2026-11-24) ----------
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

-- =====================================================================
-- v1.3 (a supabase/v1.3-napi-esemeny.sql tartalma)
-- =====================================================================
-- a v1.2-ben jött; ha az még nem futott volna, itt is létrejön
alter table public.students add column if not exists in_stats boolean not null default true;

-- osztályonként naponta egy sor: ki nyitja (sorsolás), mi jött ki, mikor nyílt
create table if not exists public.day_events(
  class_id uuid not null references public.classes(id) on delete cascade,
  day date not null,
  ev text,                         -- a napi esemény azonosítója (esemenyek.js)
  ev2 text,                        -- ünnepnapi második esemény
  opener uuid references public.students(id) on delete set null,
  opener_nick text,
  drawn_at timestamptz,
  draw jsonb,                      -- a sorsolás pillanatképe: [{nick, tickets}]
  opened_at timestamptz,
  how text,                        -- class (órán) | auto (matek nélküli nap / délután) | teacher (felülírás)
  primary key(class_id, day)
);
alter table public.day_events enable row level security;
revoke all on public.day_events from anon, authenticated;
grant select on public.day_events to authenticated;
drop policy if exists day_events_own on public.day_events;
create policy day_events_own on public.day_events for select to authenticated using (public.owns_class(class_id));

-- matekórás napok (ISO: 1 = hétfő … 7 = vasárnap); alapból hétfő, szerda, csütörtök
create or replace function public.mk_math_days(c uuid) returns int[]
language sql stable security definer set search_path = '' as $$
  select coalesce((select array(select jsonb_array_elements_text(k.config->'mathDays')::int)
                     from public.classes k where k.id = c and jsonb_typeof(k.config->'mathDays') = 'array'),
                  array[1,3,4])
$$;

-- sorsjegyek: az előző ládanyitás óta szerzett (becsült) XP alapján, minden megkezdett 20 XP egy jegy, legfeljebb 5
-- p_next: a következő ládanyitásra gyűjtött jegyek (a mai nyitás óta)
drop function if exists public.mk_tickets(uuid);
create or replace function public.mk_tickets(c uuid, p_next boolean default false)
returns table(student_id uuid, nick text, xp int, tickets int)
language sql stable security definer set search_path = '' as $$
  with w as (
    select case when p_next then
             coalesce((select d.opened_at from public.day_events d where d.class_id = c and d.day = public.mk_today()), now())
           else greatest(coalesce((select max(d.opened_at) from public.day_events d
                               where d.class_id = c and d.day < public.mk_today() and d.opened_at is not null),
                             (public.mk_today() - 1)::timestamp at time zone 'Europe/Budapest'),
                    now() - interval '4 days') end as since
  ), x as (
    select st.id, st.nick,
           coalesce(sum(case e.level when 1 then 5 when 2 then 10 when 3 then 20 else 0 end)
                    filter (where e.status = 'correct' and e.ts >= (select since from w)), 0)::int as xp
    from public.students st
    left join public.events e on e.student_id = st.id and e.ts >= (select since from w)
    where st.class_id = c and st.active and st.in_stats
    group by st.id, st.nick
  )
  select x.id, x.nick, x.xp, least(5, ceil(x.xp / 20.0))::int from x
$$;

-- az előző tanítási nap nyitója nem nyithat ma
create or replace function public.mk_prev_opener(c uuid) returns uuid
language sql stable security definer set search_path = '' as $$
  select d.opener from public.day_events d
   where d.class_id = c and d.day < public.mk_today() and d.opened_at is not null
   order by d.day desc limit 1
$$;

create or replace function public.mk_day_info(c uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'day', public.mk_today(),
    'mathDay', extract(isodow from public.mk_today())::int = any(public.mk_math_days(c)),
    'hour', extract(hour from now() at time zone 'Europe/Budapest')::int,
    'ev', d.ev, 'ev2', d.ev2, 'opened', d.opened_at is not null, 'opened_at', d.opened_at,
    'opener_nick', d.opener_nick, 'how', d.how,
    'recent', coalesce((select jsonb_agg(r.ev order by r.day desc) from
                (select x.day, x.ev from public.day_events x where x.class_id = c and x.day < public.mk_today()
                  and x.ev is not null order by x.day desc limit 12) r), '[]'::jsonb))
  from (select 1) one left join public.day_events d on d.class_id = c and d.day = public.mk_today()
$$;

-- ---------- DIÁK ----------
create or replace function public.student_day(p_token uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); c uuid; t record; nx record; info jsonb;
begin
  select class_id into c from public.students where id = sid;
  info := public.mk_day_info(c);
  select * into t from public.mk_tickets(c) k where k.student_id = sid;
  select * into nx from public.mk_tickets(c, true) k where k.student_id = sid;
  -- opened: a mai jegyek már elhasználódtak, a következő nyitásra gyűjt (és ha ma ő nyitott, holnap nem nyithat)
  return info || jsonb_build_object('myXp', coalesce(t.xp,0), 'myTickets', coalesce(t.tickets,0),
           'nextXp', coalesce(nx.xp,0), 'nextTickets', coalesce(nx.tickets,0),
           'blocked', coalesce(public.mk_prev_opener(c) = sid, false),
           'iOpen', coalesce((select d.opener = sid from public.day_events d where d.class_id = c and d.day = public.mk_today()), false));
end $$;

-- matek nélküli napon (vagy 15 óra után, ha órán nem nyílt ki) a láda magától kinyílik: az első belépő gépe választ eseményt
create or replace function public.student_day_open(p_token uuid, p_ev text, p_ev2 text default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare sid uuid := public.mk_student(p_token); c uuid; info jsonb;
begin
  select class_id into c from public.students where id = sid;
  info := public.mk_day_info(c);
  if not (info->>'opened')::boolean and (not (info->>'mathDay')::boolean or (info->>'hour')::int >= 15) then
    insert into public.day_events(class_id, day, ev, ev2, opened_at, how)
    values (c, public.mk_today(), left(p_ev,40), left(p_ev2,40), now(), 'auto')
    on conflict (class_id, day) do update set ev = excluded.ev, ev2 = excluded.ev2, opened_at = now(), how = 'auto'
      where public.day_events.opened_at is null;
  end if;
  return public.student_day(p_token);
end $$;

-- ---------- TANÁR ----------
create or replace function public.teacher_day_state(p_class uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare prev uuid;
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  prev := public.mk_prev_opener(p_class);
  return public.mk_day_info(p_class) || jsonb_build_object(
    'mathDays', to_jsonb(public.mk_math_days(p_class)),
    'tickets', coalesce((select jsonb_agg(jsonb_build_object('id', k.student_id, 'nick', k.nick, 'xp', k.xp, 'tickets', k.tickets,
                                    'blocked', coalesce(k.student_id = prev, false)) order by k.tickets desc, k.nick)
                         from public.mk_tickets(p_class) k), '[]'::jsonb),
    'draw', (select d.draw from public.day_events d where d.class_id = p_class and d.day = public.mk_today()));
end $$;

-- súlyozott sorsolás; p_exclude: aki nincs a teremben (újrasorsolásnál)
create or replace function public.teacher_day_draw(p_class uuid, p_exclude uuid[] default '{}') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare prev uuid := public.mk_prev_opener(p_class); pool jsonb; win jsonb;
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  select jsonb_agg(jsonb_build_object('id', k.student_id, 'nick', k.nick, 'tickets', k.tickets) order by k.tickets desc, k.nick) into pool
    from public.mk_tickets(p_class) k
   where k.tickets > 0 and k.student_id is distinct from prev and not (k.student_id = any(coalesce(p_exclude,'{}')));
  if pool is null then   -- senki nem gyakorolt: mindenki egy jeggyel
    select jsonb_agg(jsonb_build_object('id', st.id, 'nick', st.nick, 'tickets', 1) order by st.nick) into pool
      from public.students st
     where st.class_id = p_class and st.active and st.in_stats and st.id is distinct from prev
       and not (st.id = any(coalesce(p_exclude,'{}')));
  end if;
  if pool is null then raise exception 'no_students'; end if;
  -- súlyozott véletlen: a -ln(u)/súly szerinti legkisebb nyer
  select p into win from jsonb_array_elements(pool) p
   order by -ln(greatest(random(), 1e-12)) / (p->>'tickets')::int limit 1;
  insert into public.day_events(class_id, day, opener, opener_nick, drawn_at, draw)
  values (p_class, public.mk_today(), (win->>'id')::uuid, win->>'nick', now(), pool)
  on conflict (class_id, day) do update set opener = excluded.opener, opener_nick = excluded.opener_nick,
         drawn_at = now(), draw = excluded.draw;
  return win || jsonb_build_object('pool', pool);
end $$;

-- láda kinyitása / esemény felülírása (p_how: class | teacher)
create or replace function public.teacher_day_open(p_class uuid, p_ev text, p_ev2 text default null, p_how text default 'class') returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  insert into public.day_events(class_id, day, ev, ev2, opened_at, how)
  values (p_class, public.mk_today(), left(p_ev,40), left(p_ev2,40), now(), left(coalesce(p_how,'class'),10))
  on conflict (class_id, day) do update set ev = excluded.ev, ev2 = excluded.ev2,
         opened_at = coalesce(public.day_events.opened_at, now()), how = excluded.how;
  return public.teacher_day_state(p_class);
end $$;

-- a mai nap visszaállítása lepecsételt ládára (pl. tévedésből nyílt ki)
create or replace function public.teacher_day_reset(p_class uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if not public.owns_class(p_class) then raise exception 'forbidden'; end if;
  delete from public.day_events where class_id = p_class and day = public.mk_today();
  return public.teacher_day_state(p_class);
end $$;

revoke all on function public.mk_math_days(uuid), public.mk_tickets(uuid, boolean), public.mk_prev_opener(uuid), public.mk_day_info(uuid) from public, anon, authenticated;
grant execute on function public.student_day(uuid), public.student_day_open(uuid, text, text) to anon, authenticated;
grant execute on function public.teacher_day_state(uuid), public.teacher_day_draw(uuid, uuid[]),
                          public.teacher_day_open(uuid, text, text, text), public.teacher_day_reset(uuid) to authenticated;

