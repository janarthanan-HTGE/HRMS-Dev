create or replace function public.update_daily_training(
  p_id uuid,
  p_name text,
  p_domain text,
  p_description text,
  p_time_from time,
  p_time_to time
)
returns void
security definer
set search_path = public
as $$
update daily_training
set
  name = p_name,
  domain = p_domain,
  description = p_description,
  time_from = p_time_from,
  time_to = p_time_to
where id = p_id;
$$ language sql;

--RSL

revoke all on function public.update_daily_training from public;
grant execute on function public.update_daily_training to authenticated;
