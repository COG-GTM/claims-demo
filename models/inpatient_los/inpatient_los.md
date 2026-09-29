{% docs inpatient_los_overview %}

**Inpatient length-of-stay and cost mart.** Built on Tuva `core.encounter`
rows with `encounter_type = 'acute inpatient'`.

- **Length of stay** is Tuva's `length_of_stay` (discharge date minus admission
  date, in days).
- **Cost** is the encounter `paid_amount`; `allowed_amount` and `charge_amount`
  are carried for reference.
- **Peer groups.** Each encounter is benchmarked against its DRG
  (`drg_code_type:drg_code`) when that DRG has at least
  `var('inpatient_los_min_peer_group_size', 10)` encounters with a value for the
  metric. Otherwise it falls back to all acute inpatient encounters. If that
  population is also too small, the encounter is not evaluated.
- **Outlier rule (Tukey fences).** Quartiles use the nearest-rank method (the
  smallest value whose rank is at least `p * n`). An encounter is a high outlier
  when its value is strictly greater than `Q3 + k * IQR` and a low outlier when it
  is strictly less than `Q1 - k * IQR`, where
  `k = var('inpatient_los_outlier_iqr_multiplier', 1.5)`.
- LOS and cost are evaluated independently, so an encounter can use a DRG peer
  group for one metric and the all-inpatient group for the other.

{% enddocs %}
