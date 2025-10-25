insert into dim_date (date_key, full_date, day_of_week, day_of_month, month, month_name, quarter, year)
select
    cast(to_char(d, 'YYYYMMDD') as int) as date_key,
    d as full_date,
    extract(isodow from d) as day_of_week,
    extract(day from d) as day_of_month,
    extract(month from d) as month,
    to_char(d, 'TMMon') as month_name,
    extract(quarter from d) as quarter,
    extract(year from d) as year
from (
    select generate_series(
        '2023-01-01'::date,
        '2025-12-31'::date,
        '1 day'::interval
    ) as d
) as date_series
on conflict (date_key) do nothing;