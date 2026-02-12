create or replace function public.get_user_training_details(p_profile_id uuid)
returns json
security definer
set search_path = public
as $$
select json_build_object(
  'name',
  (select concat_ws(' ', first_name, last_name)
   from profiles
   where id = p_profile_id),

  'ongoing',
  (select coalesce(json_agg(o order by o.from_date desc), '[]'::json)
   from ongoing_training o
   where o.profile_id = p_profile_id
     and o.status = 'ongoing'),

  'daily',
  (select coalesce(json_agg(d order by d.date desc), '[]'::json)
   from daily_training d
   where d.profile_id = p_profile_id
     and d.date >= date_trunc('month', current_date)
     and d.date < date_trunc('month', current_date) + interval '1 month')
);
$$ language sql;


--permission
revoke all on function public.get_user_training_details(uuid) from public;
grant execute on function public.get_user_training_details(uuid) to authenticated;
