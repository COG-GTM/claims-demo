{% docs readmissions_mart_overview %}
# Readmissions mart

Demo-level mart built on top of the Tuva Project `readmissions` data mart
(`readmissions__encounter_augmented`). It re-derives the Tuva / CMS
Hospital-Wide Readmission (HWR) index-admission logic with one explicit flag
per exclusion rule so that every excluded encounter can be traced to a reason,
then pairs each index admission with the patient's next qualifying acute
inpatient admission to determine 30-day readmission status.

Models:

| model | grain |
| --- | --- |
| `readmissions_mart__encounter` | one row per acute inpatient encounter, with exclusion flags and `index_exclusion_reason` |
| `readmissions_mart__index_admission` | one row per index admission, with 30-day (all-cause and unplanned) readmission outcome |
| `readmissions_mart__monthly_summary` | one row per index discharge month, with unplanned 30-day readmission rate |
| `readmissions_mart__exclusion_summary` | one row per `index_status` (exclusion reason or `index admission`) |
{% enddocs %}

{% docs readmissions_mart_exclusion_rules %}
An acute inpatient encounter is an **index admission** only when **none** of the
exclusion rules below apply. Rules are evaluated independently (every
`exclusion_*_flag` is populated), and `index_exclusion_reason` reports the
first matching rule in the precedence order shown.

| # | rule | flag | logic |
| --- | --- | --- | --- |
| 1 | Data quality | `exclusion_data_quality_flag` | Tuva `disqualified_encounter_flag = 1`: missing/invalid admit or discharge date, admit after discharge, missing/invalid discharge disposition, missing/invalid primary diagnosis, no CCS diagnosis category, missing/invalid DRG, or overlaps a better encounter. Disqualified encounters are also dropped from the readmission look-up, so they can never count as a readmission. |
| 2 | Died during admission | `exclusion_died_flag` | `discharge_disposition_code = '20'` |
| 3 | Left against medical advice | `exclusion_left_ama_flag` | `discharge_disposition_code = '07'` |
| 4 | Transferred to another acute care hospital | `exclusion_acute_transfer_flag` | `discharge_disposition_code = '02'` (the receiving stay is the potential index admission instead) |
| 5 | Excluded diagnosis category | `exclusion_diagnosis_category_flag` | Primary-diagnosis CCS category is in the Tuva `readmissions__exclusion_ccs_diagnosis_category` value set: medical treatment of cancer, rehabilitation, or psychiatric. `exclusion_ccs_category` holds the matched category. |
| 6 | Insufficient 30-day lookforward | `exclusion_insufficient_lookforward_flag` | Discharge date is later than (latest discharge date in the dataset − 30 days), so a full 30-day follow-up window is not observable. |

**Readmission window.** For each index admission, the next non-disqualified
acute inpatient encounter for the same person (ordered by admit date, discharge
date) is a 30-day readmission when `days_to_readmit = admit_date(next) −
discharge_date(index)` is between 0 and 30 days inclusive (a next admission that starts before the index discharge is treated as an overlap, not a readmission). It is **unplanned**
when the readmission's Tuva `planned_flag = 0` (CMS planned readmission
algorithm: always-planned procedures/diagnoses, or potentially-planned
procedures without an acute primary diagnosis). A readmission does not need to
be an index admission itself, and only the first subsequent admission is
considered.
{% enddocs %}
