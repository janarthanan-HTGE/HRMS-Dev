create table public.daily_training (
  id uuid primary key default gen_random_uuid(),

  profile_id uuid not null
    references public.profiles(id) on delete cascade,

  name text not null,
  domain text,
  description text,

  date date not null default current_date,

  time_from time,
  time_to time,

  created_at timestamp with time zone default now()
);


create table public.ongoing_training (
  id uuid primary key default gen_random_uuid(),

  profile_id uuid not null
    references public.profiles(id) on delete cascade,

  name text not null,
  domain text,

  from_date date not null,
  to_date date not null,

  time_from time,
  time_to time,

  status text not null default 'ongoing'
    check (status in ('ongoing', 'completed', 'discontinue')),

  created_at timestamp with time zone default now()
);


--RSL : 

alter table public.daily_training enable row level security;
alter table public.ongoing_training enable row level security;

-- SELECT — user can view only their records


create policy "Users can view own daily training"
on public.daily_training
for select
using (
  auth.uid() = (
    select user_id
    from public.profiles
    where profiles.id = daily_training.profile_id
  )
);

--INSERT — user can insert only for themselves
create policy "Users can insert own daily training"
on public.daily_training
for insert
with check (
  auth.uid() = (
    select user_id
    from public.profiles
    where profiles.id = daily_training.profile_id
  )
);

--ongoing select
create policy "Users can view own ongoing training"
on public.ongoing_training
for select
using (
  auth.uid() = (
    select user_id
    from public.profiles
    where profiles.id = ongoing_training.profile_id
  )
);

--insert 
create policy "Users can insert own ongoing training"
on public.ongoing_training
for insert
with check (
  auth.uid() = (
    select user_id
    from public.profiles
    where profiles.id = ongoing_training.profile_id
  )
);

--fix RSL 
drop policy if exists "Users can update their own training"
on ongoing_training;

create policy "Users can update their own training"
on ongoing_training
for update
using (
  auth.uid() = (
    select user_id
    from profiles
    where profiles.id = ongoing_training.profile_id
  )
)
with check (
  auth.uid() = (
    select user_id
    from profiles
    where profiles.id = ongoing_training.profile_id
  )
);
