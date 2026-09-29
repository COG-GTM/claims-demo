{{ config(
     enabled = var('claims_enabled', var('tuva_marts_enabled', False)) | as_bool
   )
}}

-- Every outlier flag must agree with the encounter value and the fence it was
-- benchmarked against; encounters with no peer group must not be flagged.
select
      encounter_id
    , length_of_stay
    , los_lower_fence
    , los_upper_fence
    , los_high_outlier_flag
    , los_low_outlier_flag
    , paid_amount
    , cost_lower_fence
    , cost_upper_fence
    , cost_high_outlier_flag
    , cost_low_outlier_flag
from {{ ref('inpatient_los__encounter_outliers') }}
where los_high_outlier_flag <> case when length_of_stay > los_upper_fence then 1 else 0 end
   or los_low_outlier_flag <> case when length_of_stay < los_lower_fence then 1 else 0 end
   or cost_high_outlier_flag <> case when paid_amount > cost_upper_fence then 1 else 0 end
   or cost_low_outlier_flag <> case when paid_amount < cost_lower_fence then 1 else 0 end
   or (los_peer_group_level is null and los_high_outlier_flag + los_low_outlier_flag > 0)
   or (cost_peer_group_level is null and cost_high_outlier_flag + cost_low_outlier_flag > 0)
   or (los_high_outlier_flag = 1 and los_low_outlier_flag = 1)
   or (cost_high_outlier_flag = 1 and cost_low_outlier_flag = 1)
