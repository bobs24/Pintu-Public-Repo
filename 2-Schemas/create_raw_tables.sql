create table if not exists raw_users (
    user_id varchar(255) null,
    region varchar(255) null,
    signup_date varchar(255) null
);

create table if not exists raw_tokens (
    token_id varchar(255) null,
    token_name varchar(255) null,
    category varchar(255) null
);

create table if not exists raw_trades (
    trade_id varchar(255) null,
    user_id varchar(255) null,
    token_id varchar(255) null,
    side varchar(255) null,
    price_usd varchar(255) null,
    quantity varchar(255) null,
    status varchar(255) null,
    trade_created_time varchar(255) null,
    trade_updated_time varchar(255) null
);

create table if not exists raw_p2p_transfers (
    transfer_id varchar(255) null,
    sender_id varchar(255) null,
    receiver_id varchar(255) null,
    token_id varchar(255) null,
    amount varchar(255) null,
    status varchar(255) null,
    transfer_created_time varchar(255) null,
    transfer_updated_time varchar(255) null
);