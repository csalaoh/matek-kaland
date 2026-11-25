-- =====================================================================
-- Matek-kaland v1.3 – Óranyitó láda (napi esemény osztályonként)
-- Futtatás: Supabase → SQL Editor → New query → beilleszt → Run.
-- Többször is lefuttatható, adatot nem töröl.
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

-- ellenőrzés
select 'v1.3 kész' as allapot, count(*) as eddigi_napok from public.day_events;
