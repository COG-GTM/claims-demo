{% docs chronic_conditions_prevalence %}
Annual chronic condition prevalence for the enrolled claims population, built on top of the
Tuva chronic conditions grouper (`chronic_conditions__tuva_chronic_conditions_long`).

**Grain:** one row per `prevalence_year` and `condition`. Every condition that appears in the
grouper is reported for every year that has enrollment, zero-filled when there are no cases.

**Denominator (`eligible_members`):** distinct members with at least one member month in the year
(`core__member_months`).

**Numerator (`members_with_condition`):** distinct members enrolled in the year whose first
diagnosis for the condition is on or before the end of that year. Chronic conditions are treated as
persistent once diagnosed, so a member diagnosed in 2017 and still enrolled in 2018 counts toward
2018 prevalence even without a new diagnosis claim in 2018.

**Incidence (`newly_diagnosed_members`):** members whose first diagnosis for the condition falls in
the year. Because the grouper only sees diagnoses present in the data, members with a condition
diagnosed before the data window will appear as "new" in the first year of data.

Persons who appear in the grouper but have no member months (for example clinical-only patients)
are excluded, since they have no eligibility-based denominator.
{% enddocs %}
