-- Category shares within a month must sum to 1 whenever the month has paid spend.
select dispensing_month, sum(share_of_month_paid) as total_share
from {{ ref('pharmacy_spend__brand_generic_monthly') }}
group by dispensing_month
having sum(paid_amount) <> 0
   and abs(sum(share_of_month_paid) - 1) > 0.0001
