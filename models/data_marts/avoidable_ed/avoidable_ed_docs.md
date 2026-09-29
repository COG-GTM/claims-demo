{% docs avoidable_ed__member_month_summary %}
Avoidable emergency department (ED) utilization summarised at the person_id and
year_month grain.

**Spine.** One row for every month a person is enrolled (from
`core__member_months`) plus any month in which the person had an ED visit while
not enrolled (`enrolled_flag = 0`). Enrolled months with no ED activity are kept
with zero counts so the table can be used directly as a denominator for
PMPM and per-1,000 rates.

**ED visits.** Counted from `core__encounter` where
`encounter_type = 'emergency department'`, assigned to the month of
`encounter_end_date` (the same convention used by `ed_classification__summary`).

**Avoidable definition.** ED visits are classified by the Tuva
`ed_classification` mart, which applies the NYU/Johnston ED algorithm to the
primary diagnosis and assigns each visit to its highest-probability category.
A visit is counted as avoidable when its category is in the
`avoidable_ed_classifications` project variable, which defaults to:

| code     | classification                                      |
|----------|-----------------------------------------------------|
| `noner`  | Non-Emergent                                        |
| `epct`   | Emergent, Primary Care Treatable                    |
| `edcnpa` | Emergent, ED Care Needed, Preventable/Avoidable     |

Visits whose primary diagnosis cannot be classified are included in `ed_visits`
but not in `classified_ed_visits` or `avoidable_ed_visits`.

The mart is enabled by `avoidable_ed_enabled`, falling back to
`ed_classification_enabled`, `claims_enabled`, then `tuva_marts_enabled`.
{% enddocs %}
