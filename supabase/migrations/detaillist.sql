--RSL

create or replace function public.get_training_summary()
returns table (
  id uuid,
  name text,
  ongoing_count bigint,
  daily_count bigint
)
security definer
set search_path = public
as $$
select
  p.id,
  concat_ws(' ', p.first_name, p.last_name) as name,

  count(o.*) filter (where o.status = 'ongoing') as ongoing_count,

  count(d.*) filter (
    where d.date >= date_trunc('month', current_date)
      and d.date < date_trunc('month', current_date) + interval '1 month'
  ) as daily_count

from profiles p
left join ongoing_training o on o.profile_id = p.id
left join daily_training d on d.profile_id = p.id

group by
  p.id,
  p.first_name,
  p.last_name

order by
  p.first_name,
  p.last_name;
$$ language sql;


--permission 
revoke all on function public.get_training_summary() from public;
grant execute on function public.get_training_summary() to authenticated;
