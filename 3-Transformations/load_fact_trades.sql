insert into fact_trades (
    trade_key,
    user_key,
    token_key,
    trade_date_key,
    trade_timestamp_utc,
    side,
    price_usd,
    quantity,
    volume_usd
)
select
    raw.trade_id as trade_key,
    du.user_key,
    dt.token_key,
    
    cast(to_char(cast(raw.trade_updated_time as timestamp), 'YYYYMMDD') as int) as trade_date_key,
    cast(raw.trade_updated_time as timestamp) as trade_timestamp_utc,
    
    raw.side,
    
    cast(raw.price_usd as numeric(38, 18)),
    cast(raw.quantity as numeric(38, 18)),
    
    (cast(raw.price_usd as numeric(38, 18)) * cast(raw.quantity as numeric(38, 18))) as volume_usd
    
from
    raw_trades as raw
join
    dim_users as du on raw.user_id = du.user_id
join
    dim_tokens as dt on raw.token_id = dt.token_id
where
    raw.status = 'FILLED'
on conflict (trade_key) do nothing;