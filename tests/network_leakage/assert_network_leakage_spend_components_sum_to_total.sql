-- In-network + out-of-network + unknown paid equals total paid for every cohort.
select *
from {{ ref('network_leakage__member_cohort_summary') }}
where abs(
    in_network_paid_amount
    + out_of_network_paid_amount
    + unknown_network_paid_amount
    - total_paid_amount
) > 0.01
