{% docs eligibility_mart_assumptions %}

Member-months / eligibility summary mart built from the `eligibility` seed.

**Grain and keys**
- Coverage is evaluated per `data_source` + `person_id` + `payer` + `plan`. Spans for
  different payers/plans are never merged with each other, so a person covered by two
  plans in the same month contributes one member month to each plan.
- `member_id` is carried along as the max value within the grain; it is not part of the key.

**Span cleaning**
- Rows with no `person_id` or no `enrollment_start_date` are excluded.
- A null `enrollment_end_date` is treated as open-ended and capped at the dataset's
  as-of date (latest `enrollment_end_date` in the seed, falling back to the latest
  `enrollment_start_date`). Such spans carry `open_ended_flag = 1`.
- If `death_date` falls before the span end, coverage ends on `death_date`
  (`death_truncated_flag = 1`).
- Spans whose end date is before their start date after the steps above (bad data, or
  death before enrollment began) are dropped.

**Overlaps**
- Overlapping, duplicate, contained and contiguous spans (next start = prior end + 1 day)
  are merged into a single continuous enrollment span (gaps-and-islands), so a covered
  day is never counted twice. `source_span_count` records how many seed rows were merged.
- A gap of one or more uncovered days starts a new enrollment span.

**Member months**
- A member month is counted when the member has coverage on **at least one day** of the
  calendar month (`member_month = 1` for every row). This matches the Tuva
  `core.member_months` convention of joining on `start <= month_end and end >= month_start`.
- Partial coverage is exposed rather than hidden: `covered_days`, `days_in_month`,
  `member_month_fraction` (covered_days / days_in_month, for pro-rated PMPM),
  `full_month_flag`, and `enrolled_first_of_month_flag` (for the "enrolled on the 1st"
  convention used by some payers).
- Multiple disjoint spans in the same month (e.g. 1st-10th and 20th-31st) sum their days
  into a single member-month row.
- Months come from the Tuva `reference_data__calendar` seed, so spans outside the
  calendar's date range produce no member months.

{% enddocs %}
