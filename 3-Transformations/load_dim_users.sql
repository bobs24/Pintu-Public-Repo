insert into dim_users (user_id, region, signup_date)
select
    user_id,
    region,
    to_date(signup_date, 'YYYY-MM-DD') as signup_date
from
    raw_users
on conflict (user_id) do nothing;