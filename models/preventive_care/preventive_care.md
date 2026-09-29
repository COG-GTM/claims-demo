{% docs preventive_care__overview %}
Preventive care quality measures mart. Calculates three claims-based preventive screening
measures (BCS, CCS, COL) on top of the Tuva core data model for a twelve-month performance
period ending on the `quality_measures_period_end` var.

Shared rules applied to every measure:

- **Performance period**: twelve months ending on `quality_measures_period_end` (2018-01-01 to
  2018-12-31 in the demo). Lookback windows are counted in calendar months before the period
  begin, so the period is expected to start on the first day of a month.
- **Age**: age in whole years on the performance period end date.
- **Continuous enrollment**: enrolled for the whole performance period with at most
  `preventive_care_max_enrollment_gap_days` (default 45) uncovered days, from `core__eligibility`.
- **Deceased**: patients with a `death_date` on or before the performance period end are not
  in any denominator.
- **Hospice**: any hospice service (HCPCS hospice codes or hospice revenue codes) during the
  performance period is a denominator exclusion for every measure.
- **Evidence sources**: HCPCS/CPT and revenue codes on `core__medical_claim` lines, plus
  ICD-10-PCS / HCPCS codes from `core__procedure` and ICD-10-CM codes from `core__condition`.
- **Rate**: `numerator / (denominator - exclusions)`. Excluded patients never count in the
  numerator.

Code lists live in `macros/preventive_care/preventive_care_measure_definitions.sql` and are a
curated, claims-focused subset of the NCQA HEDIS / CMS eCQM value sets, not the full licensed
value sets.
{% enddocs %}


{% docs preventive_care__measure_bcs %}
**BCS - Breast Cancer Screening** (HEDIS BCS-E / CMS125)

- **Denominator**: female, age 52-74 at the end of the performance period, continuously enrolled.
- **Numerator**: a mammogram (CPT 77061-77063, 77065-77067; HCPCS G0202, G0204, G0206) between
  October 1 two years before the performance period end and the performance period end
  (the performance period plus a 15 month lookback).
- **Exclusions**:
  - Bilateral mastectomy any time through the performance period end (ICD-10-CM Z90.13,
    ICD-10-PCS 0HTV0ZZ), or evidence of both a left (Z90.12 / 0HTU0ZZ) and a right
    (Z90.11 / 0HTT0ZZ) unilateral mastectomy.
  - Hospice services during the performance period.
{% enddocs %}


{% docs preventive_care__measure_ccs %}
**CCS - Cervical Cancer Screening** (HEDIS CCS-E / CMS124)

- **Denominator**: female, age 24-64 at the end of the performance period, continuously enrolled.
- **Numerator**, either of:
  - Cervical cytology (Pap) during the performance period or the two years before it, performed
    when the patient was 21 or older.
  - High-risk HPV testing (CPT 87624, 87625; HCPCS G0476) during the performance period or the
    four years before it, performed when the patient was 30 or older.
- **Exclusions**:
  - Hysterectomy with no residual cervix, or congenital absence of cervix, any time through the
    performance period end (ICD-10-CM Z90.710, Z90.712, Q51.5; ICD-10-PCS 0UTC*ZZ; hysterectomy CPT codes).
  - Hospice services during the performance period.
{% enddocs %}


{% docs preventive_care__measure_col %}
**COL - Colorectal Cancer Screening** (HEDIS COL-E / CMS130)

- **Denominator**: any sex, age 46-75 at the end of the performance period, continuously enrolled.
- **Numerator**, any of:
  - Colonoscopy during the performance period or the nine years before it.
  - Flexible sigmoidoscopy or CT colonography during the performance period or the four years before it.
  - Stool DNA with FIT test (CPT 81528) during the performance period or the two years before it.
  - Fecal occult blood test (CPT 82270, 82274; HCPCS G0328) during the performance period.
- **Exclusions**:
  - Colorectal cancer (ICD-10-CM C18.*, C19, C20, C21.2, C21.8, C78.5, Z85.038, Z85.048) or a
    total colectomy (ICD-10-PCS 0DTE*ZZ; CPT 44150-44158, 44210-44212) any time through the
    performance period end.
  - Hospice services during the performance period.
{% enddocs %}
