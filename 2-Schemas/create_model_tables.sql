create table if not exists dim_users (
    user_key serial primary key,
    user_id varchar(20) unique not null,
    region varchar(50),
    signup_date date,
    etl_load_time timestamp default current_timestamp
);

create table if not exists dim_tokens (
    token_key serial primary key,
    token_id varchar(10) unique not null,
    token_name varchar(50),
    category varchar(50),
    etl_load_time timestamp default current_timestamp   
);

create table if not exists dim_date (
    date_key int primary key,
    full_date date not null,
    day_of_week int,
    day_of_month int,
    month int,
    month_name varchar(3),
    quarter int,
    year int
);

create table if not exists fact_trades (
    trade_key varchar(50) primary key,
    user_key int not null,
    token_key int not null,
    trade_date_key int not null,
    trade_timestamp_utc timestamp,
    side varchar(10),
    price_usd numeric(38, 18),
    quantity numeric(38, 18),
    volume_usd numeric(38, 18),
    
    foreign key (user_key) references dim_users(user_key),
    foreign key (token_key) references dim_tokens(token_key),
    foreign key (trade_date_key) references dim_date(date_key)
);

create table if not exists fact_p2p_transfers (
    transfer_key varchar(50) primary key,
    sender_user_key int not null,
    receiver_user_key int not null,
    token_key int not null,
    transfer_date_key int not null,
    transfer_timestamp_utc timestamp,
    amount_token numeric(38, 18),
    amount_usd numeric(38, 18),
    
    foreign key (sender_user_key) references dim_users(user_key),
    foreign key (receiver_user_key) references dim_users(user_key),
    foreign key (token_key) references dim_tokens(token_key),
    foreign key (transfer_date_key) references dim_date(date_key)
);