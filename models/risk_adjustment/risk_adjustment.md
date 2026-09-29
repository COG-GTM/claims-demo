{% docs risk_adjustment__member_year_hccs %}
One row per member (`person_id` + `payer`), calendar `member_year`, and HCC
that survives the CMS-HCC hierarchy. Built from `core.condition` ICD-10-CM
diagnoses using the Tuva CMS-HCC value sets. See
`risk_adjustment__member_year_summary` for the assumptions behind this mart.
{% enddocs %}

{% docs risk_adjustment__member_year_summary %}
One row per member (`person_id` + `payer`) and calendar year with at least one
enrolled month in `core.member_months`. Member years without any HCC are kept
with `hcc_count = 0` so the table can be used as a denominator.

**Assumptions and simplifications**

This mart is an HCC-style condition rollup for population analytics. It is
not a CMS payment calculation; use the Tuva `cms_hcc` mart for RAF scores.

1. **Member year = calendar year of enrollment.** Member years come from
   `core.member_months`. Plans within the same payer are combined.
2. **Diagnosis year = calendar year of `recorded_date`.** A diagnosis only
   counts if the member was enrolled with the same payer at some point in that
   calendar year. Conditions without a payer (e.g. clinical-only records) or
   without a `recorded_date` are excluded.
3. **All ICD-10-CM diagnoses count.** CMS's risk-adjustable filter (eligible
   CPT/HCPCS, bill types, face-to-face encounters) is *not* applied, so HCC
   prevalence will run higher than in the `cms_hcc` mart.
4. **One crosswalk for every year.** Every member year is mapped with a single
   ICD-10-CM → HCC crosswalk year: `var('risk_adjustment_mapping_year')`,
   defaulting to the latest payment year in `cms_hcc__icd_10_cm_mappings`.
   This keeps HCC definitions consistent across years (the demo data is
   2016–2018, older than any crosswalk shipped with Tuva) but means codes
   retired before the crosswalk year will not map.
5. **Model version.** `var('risk_adjustment_model_version')`, default
   `CMS-HCC-V28`; `CMS-HCC-V24` is also supported. The same version drives
   the crosswalk column, hierarchy, and coefficients.
6. **Hierarchy.** An HCC is dropped when a higher-ranked HCC that excludes it
   (per `cms_hcc__disease_hierarchy`) is present in the same member year.
   The V28 heart-failure (HCC 223) patch and disease interactions are not
   applied.
7. **Reference weight, not RAF.** `reference_coefficient` is the community,
   non-dual, aged, continuing-enrollment disease coefficient regardless of the
   member's actual segment. `raw_disease_score` is the sum of those weights
   and excludes demographic, interaction, HCC-count, normalization, and MA
   coding-intensity adjustments.
{% enddocs %}
