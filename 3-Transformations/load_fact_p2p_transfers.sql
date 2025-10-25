create temporary table temp_daily_avg_price as
select
    trade_date_key,
    token_key,
    avg(price_usd) as avg_daily_price_usd
from
    fact_trades
group by
    1, 2;
    

insert into fact_p2p_transfers (
    transfer_key,
    sender_user_key,
    receiver_user_key,
    token_key,
    transfer_date_key,
    transfer_timestamp_utc,
    amount_token,
    amount_usd
)
select
    raw.transfer_id as transfer_key,
    du_sender.user_key as sender_user_key,
    du_receiver.user_key as receiver_user_key,
    dt.token_key,
    cast(to_char(cast(raw.transfer_updated_time as timestamp), 'YYYYMMDD') as int) as transfer_date_key,
    cast(raw.transfer_updated_time as timestamp) as transfer_timestamp_utc,
    
    cast(raw.amount as numeric(38, 18)) as amount_token,
    
    (cast(raw.amount as numeric(38, 18)) * coalesce(price.avg_daily_price_usd, 0)) as amount_usd
    
from
    raw_p2p_transfers as raw
join
    dim_users as du_sender on raw.sender_id = du_sender.user_id
join
    dim_users as du_receiver on raw.receiver_id = du_receiver.user_id
join
    dim_tokens as dt on raw.token_id = dt.token_id
left join
    temp_daily_avg_price as price 
    on dt.token_key = price.token_key 
    and cast(to_char(cast(raw.transfer_updated_time as timestamp), 'YYYYMMDD') as int) = price.trade_date_key
where
    raw.status = 'SUCCESS'
on conflict (transfer_key) do nothing;