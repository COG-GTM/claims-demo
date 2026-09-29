{% docs ed_utilization_overview %}
Emergency department (ED) utilization expressed as ED visits per 1,000 member
months, built from the Tuva `core.encounter` model and `core.member_months`.

**Numerator:** distinct `core.encounter` rows with
`encounter_type = 'emergency department'`, bucketed by the calendar month of
`encounter_start_date`. The Tuva encounter grouper rolls ED visits that result
in an inpatient admission into the inpatient encounter, so those are not counted
here (treat-and-release / observation-free ED visits only).

**Denominator:** rows in `core.member_months` (one per person, month, payer,
plan and data source).

**Attribution:** an ED visit is counted against the member month(s) matching
the person, month and data source. ED visits in months where the person has no
enrollment are excluded, because there is no denominator to express them
against. If a person has more than one payer/plan in the same month, the visit
is counted in each of those member months.

**Rate:** `ed_visits * 1000 / member_months`. Aggregate across rows by summing
`ed_visits` and `member_months` and recomputing the rate; do not average the
per-row rate.
{% enddocs %}
