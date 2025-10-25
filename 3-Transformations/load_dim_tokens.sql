insert into dim_tokens (token_id, token_name, category)
select
    token_id,
    token_name,
    category
from
    raw_tokens
on conflict (token_id) do nothing;